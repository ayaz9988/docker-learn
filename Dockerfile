# ═══════════════════════════════════════════════════════════════════════════════
# Dockerfile — Multi-stage build for a Node.js / TypeScript / SQLite API
# ═══════════════════════════════════════════════════════════════════════════════
#
# Dockerfile reference:  https://docs.docker.com/reference/dockerfile/
# Best practices:        https://docs.docker.com/develop/develop-images/dockerfile_best-practices/
#
# ── Why multi-stage? ─────────────────────────────────────────────────────────
# A single-stage Dockerfile typically looks like:
#
#   FROM node:24-slim
#   WORKDIR /app
#   COPY . .
#   RUN npm install && npm run build
#   CMD ["node", "dist/index.js"]
#
# Problems with that approach:
#   - The final image contains devDependencies (typescript, @types/*, tsx, etc.)
#     which are only needed to BUILD the app, not to RUN it.
#   - The image is larger (more disk, slower deploys, bigger attack surface).
#   - Source code (.ts files) ends up in production unnecessarily.
#
# Multi-stage solves this by using multiple FROM statements. Each FROM starts
# a new stage. Earlier stages contain build tooling; later stages copy only
# the final artifacts. The publishable image is ONLY the last stage.
#
# ── Stage overview ──────────────────────────────────────────────────────────
#   base         — shared config (workdir, image base)
#   dependencies — install ALL npm packages (dev + prod)
#   build        — compile TypeScript → dist/
#   release      — minimal image with only runtime files
#
# ── Why root during build? ──────────────────────────────────────────────────
# Stages 1-3 run as root. This is intentional and safe because:
#   - Build stages are never exposed to external traffic
#   - npm ci / npm install need to write to /app and /tmp — root avoids EACCES
#   - No need for --chown flags on every COPY
# The non-root USER node is applied only in the release stage (stage 4),
# which is the container that actually serves requests.
#
# ═══════════════════════════════════════════════════════════════════════════════


# ── Stage 1: base ──────────────────────────────────────────────────────────────
#
# Sets up the foundation shared by all build stages.
# Only stage 4 (release) uses a fresh FROM to discard build layers.

# FROM — every stage starts with FROM. It sets the base image.
# node:24-slim is a Debian-based image with Node.js pre-installed.
# "Slim" variants strip out documentation, locales, and other non-essentials
# while keeping the full glibc toolchain (unlike Alpine). This matters for
# native Node.js modules like better-sqlite3 which need a C++ compiler.
#
# Available variants (from smallest to largest):
#   node:24-alpine     — ~120 MB, uses musl libc (can break native modules)
#   node:24-slim       — ~180 MB, Debian-based, good balance (ours)
#   node:24            — ~350 MB, full Debian with build tools
#   node:24-bookworm   — same as node:24
#   gcr.io/distroless/nodejs  — ~120 MB, no shell, no package manager (advanced)
#
# AS names the stage so other stages can reference it (FROM ... AS base).
FROM node:24-slim AS base

# WORKDIR sets the working directory for all subsequent instructions.
# If the directory doesn't exist, Docker creates it.
# All relative paths in COPY, RUN, CMD are relative to this.
# Best practice: use a non-root directory like /app, never the root filesystem.
WORKDIR /app


# ── Stage 2: dependencies ─────────────────────────────────────────────────────
#
# Installs ALL npm packages (both dependencies and devDependencies).
# The COPY is split into two steps for layer caching:
#   Step 1: COPY package*.json → RUN npm ci
#   Step 2: COPY src/
#
# Why split? Each instruction creates a layer. If only source files change,
# Docker reuses the cached "npm ci" layer and skips the expensive install.
# This saves 30-60 seconds on every rebuild during development.
FROM base AS dependencies

# COPY copies files from the build context (your project directory) into
# the image. The syntax is: COPY <source> <destination>
# Source is relative to the build context; destination is relative to WORKDIR.
#
# Using a wildcard "package*.json" catches both package.json AND
# package-lock.json. The lockfile is critical for reproducible builds.
COPY package*.json ./

# RUN executes a command during the build and commits the result as a new layer.
#
# npm ci vs npm install:
#   npm ci (clean install):
#     - Requires package-lock.json (fails if missing or mismatched)
#     - Deletes node_modules and re-installs from scratch
#     - Faster (skips resolution, uses lockfile directly)
#     - Reproducible — every build gets exact same versions
#     - Best for CI/CD and Docker builds
#
#   npm install:
#     - May update the lockfile (mutates state during build — bad)
#     - Slower (resolves versions if lockfile is stale)
#     - Allows version ranges to resolve differently each time
#     - Better for local development when adding packages
#
# 🚨 Common pitfall: if npm ci seems slow, ensure your .dockerignore excludes
# node_modules. Otherwise Docker sends host node_modules to the daemon,
# only to have npm ci delete and recreate them.
RUN npm ci


# ── Stage 3: build ─────────────────────────────────────────────────────────────
#
# Compiles TypeScript to JavaScript using the devDependencies installed above
# (typescript, @types/*, tsconfig.json).
FROM dependencies AS build

# Copy the full source tree (node_modules is already present from the
# dependencies stage since we inherit FROM dependencies).
COPY src ./src/
COPY tsconfig.json ./

# Compile TypeScript. The script "build" is defined in package.json as:
#   "build": "tsc -p tsconfig.json"
# This outputs compiled JavaScript to dist/ (as configured in tsconfig.json).
#
# Alternative: if you don't want to pre-compile, you could use tsx at runtime:
#   CMD ["tsx", "src/index.ts"]
# But this is slower at startup and requires tsx in the final image.
RUN npm run build


# ── Stage 4: release (production) ─────────────────────────────────────────────
#
# The final, publishable image. Starts from a FRESH node:24-slim to discard
# all build layers (compilers, devDependencies, source code, npm cache).
# Only what is explicitly COPY'd into this stage ends up in the final image.
FROM node:24-slim AS release

WORKDIR /app

# RUN as root (before USER node) to create the data directory and give it
# the correct ownership. If we did this after USER node, the mkdir would
# work (since /app is owned by node) but chown would fail (requires root).
#
# The `/app/data` directory is where the SQLite database file lives.
# When a named volume is mounted here at runtime, Docker overlays it.
# The mount point inherits the image's permissions — which is why we
# ensure it's owned by node:node before the overlay takes effect.
#
# mkdir -p: creates the directory and any missing parents.
# chown -R: recursively changes ownership to user "node" (UID 1000).
#           The node user exists in the official Node image by default.
RUN mkdir -p /app/data && chown -R node:node /app /app/data

# Switch to the non-root user "node" for the remainder of the Dockerfile
# and at runtime. This is a security best practice — if an attacker exploits
# the Node.js process, they get a non-root shell with limited privileges.
#
# Without this line, the container runs as root. A compromised process
# could read/write any file on the host through bind mounts.
USER node

# ── COPY from earlier stages ──────────────────────────────────────────────
#
# These COPY instructions use --from=<stage> to copy files from a previous
# build stage instead of from the build context. The pattern is:
#   COPY --chown=<user> --from=<stage> <source-in-stage> <destination>
#
# We COPY four things:
#
#   1. package.json     — from dependencies (metadata for Prisma etc.)
#   2. node_modules     — from dependencies (all deps; trimmed next step)
#   3. dist/            — from build (compiled JavaScript)
#
# Each COPY is separate so Docker can cache them independently. If only
# source files change, package.json and node_modules layers are reused.
#
# --chown=node ensures the copied files are owned by the node user, not
# root. This is necessary because COPY always operates as root regardless
# of the current USER setting. Without --chown, files would be owned by
# root and the node user couldn't write to them.
COPY --chown=node --from=dependencies /app/package.json ./
COPY --chown=node --from=dependencies /app/node_modules ./node_modules
COPY --chown=node --from=build /app/dist ./dist

# Prune devDependencies from node_modules.
# The dependencies stage installed ALL packages (dev + prod). After
# building, we no longer need TypeScript, @types/*, tsx, etc.
#
# npm install --only=production removes devDependencies from node_modules.
# This shrinks the image size and reduces the attack surface (fewer
# packages = fewer potential vulnerabilities).
#
# Alternative: npm prune --production (same effect, slower).
RUN npm install --only=production

# ── HEALTHCHECK ────────────────────────────────────────────────────────────
#
# Tells Docker how to test if the container is still working.
# Docker runs the command every 30s with a 10s timeout. If it fails
# (exits non-zero) for 3 consecutive attempts, the container's status
# changes from "healthy" to "unhealthy".
#
# Why is this important?
#   - Orchestration (Docker Swarm, Kubernetes) restarts unhealthy containers
#   - docker-compose's depends_on can wait for service_healthy
#   - Monitoring tools can alert on unhealthy containers
#
# The check: run Node.js inline with the built-in fetch() (Node 18+)
# to hit the app's root endpoint. If the app responds 200 OK, exit 0.
# Otherwise (crash, hang, 404, 500), exit 1.
#
# What to check: hit an endpoint that validates the app is truly healthy.
#   - Simple: GET / (root) — checks the process is alive
#   - Better: GET /health — a dedicated endpoint that checks DB connectivity
#   - Best: an endpoint that also verifies the app can make outbound calls
#
# Alternative check using curl (requires curl in the image):
#   HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
#     CMD curl -f http://localhost:3000 || exit 1
#
# Why we use node -e instead of curl:
#   - node:24-slim doesn't ship curl; installing it adds ~15 MB
#   - Node's fetch() is built-in since Node 18 (no extra packages)
#   - One less dependency to update/audit
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD ["node", "-e", "fetch('http://localhost:3000').then(r => process.exit(r.ok?0:1))"]

# ── CMD ────────────────────────────────────────────────────────────────────
#
# The default command when the container starts. There can be only one CMD
# per Dockerfile (last one wins). Can be overridden at runtime:
#   docker run task-api node dist/index.js --some-flag
#
# Two forms:
#   Shell form:  CMD node dist/index.js                    (runs via /bin/sh -c)
#   Exec form:   CMD ["node", "dist/index.js"]             (runs directly) ← we use this
#
# Exec form is preferred because:
#   - No shell overhead (cleaner process tree, no PID 1 issues)
#   - Shell form spawns a subprocess — signals (SIGTERM) go to the shell,
#     not to Node, so "docker stop" may not shut down gracefully
#
# 🚨 Common pitfall: never do:
#   CMD ["npm", "start"]
# This runs npm as the main process, which spawns Node as a child.
# Docker only tracks the npm PID, and signals won't reach Node.
# Always run the runtime directly.
CMD ["node", "dist/index.js"]


# ═══════════════════════════════════════════════════════════════════════════════
# ── Extra Notes ────────────────────────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════════════════════
#
# ── ENV vs ARG ────────────────────────────────────────────────────────────
# ENV: environment variable available at build time AND runtime.
#      docker run -e MY_VAR=value can override it.
# ARG: build-time only variable. Not available in the running container.
#      docker build --build-arg MY_VAR=value.
#
# Example:
#   ARG NODE_ENV=production
#   ENV NODE_ENV=$NODE_ENV
#
# ── EXPOSE ────────────────────────────────────────────────────────────────
# EXPOSE is purely documentation. It does NOT publish the port.
# It tells users of the image: "this container listens on port 3000".
# To actually make it accessible, you still need -p 3000:3000 (or ports: in compose).
# We omitted it because compose handles port mapping explicitly.
#
# ── Why no RUN apt-get update? ────────────────────────────────────────────
# node:24-slim already has everything we need. If you needed a system
# package (like curl, git, ffmpeg), you'd add:
#   RUN apt-get update && apt-get install -y --no-install-recommends \
#       curl \
#       && rm -rf /var/lib/apt/lists/*
#
# Always clean the apt cache in the same layer to keep the image small.
#
# ── ONBUILD ────────────────────────────────────────────────────────────────
# A special instruction that runs when this image is used as a base for
# another Dockerfile. Common for base images that are extended by projects.
# Example: the official node image uses ONBUILD to auto-copy package.json.
#
# ── Common troubleshooting ────────────────────────────────────────────────
#
# "npm ci fails with EACCES" → check that /app is writable by the current
#   user (root during build). Or check .dockerignore for missing entries.
#
# "unable to open database file" → the node user can't write to the
#   volume mount. Either: (1) use a named volume, (2) chown the mount
#   point in the Dockerfile, or (3) set DB_PATH to a writable location.
#
# "Image is 1GB+" → you likely have devDependencies in the final image.
#   Check that the release stage does NOT contain package.json with
#   devDependencies, and that node_modules was pruned.
#
# "Container exits immediately" → run it locally to see the error:
#   docker run --rm task-api
#   Or check logs: docker logs <container-id>
