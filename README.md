# docker-learn

My personal repo for learning backend infrastructure with Docker.

## What's here

- **Node.js/Express API** — SQLite + Redis caching
- **Dockerfile** — multi-stage, slim, healthchecked, USER node
- **Docker Compose** — dev/prod profiles, resource limits, logging
- **Docker Swarm** — replicas, rolling updates, routing mesh
- **CI/CD** — GitHub Actions → build → push to GHCR

## Stack

TypeScript, Express, SQLite, Redis, ioredis, Docker, Swarm, GitHub Actions

## Projects across repos

| Project | Stack |
|---------|-------|
| backend_complaints_block_5 | Express 5, Prisma, PostgreSQL, Zod, JWT, Docker |
| job-board | Express 5, Drizzle, PostgreSQL, better-auth, Zod, Winston |
| lms-portal-backend | Express 4, PostgreSQL, Socket.io, BullMQ, OpenAI, Stripe |
| lms-portal-interface | Next.js 14, React, Tailwind, MUI |
| virtualoffice | Express 4, React, SQLite, Zustand, Zoom SDK |
| aws-s3-signed-urls | TypeScript, AWS SDK v3 |
| docker-learn | Express 4, SQLite, Redis, Docker, Swarm |

## Path to senior backend

### Already covered

| Area | What I've done |
|------|---------------|
| REST APIs | Express 4/5, routing, middleware, error handling |
| Databases | SQLite, PostgreSQL, Prisma, Drizzle, raw SQL |
| Caching | Redis, ioredis, cache invalidation |
| Auth | JWT, better-auth, OTP, session management |
| File uploads | Multer, S3 presigned URLs, Cloudinary signed URLs |
| Real-time | Socket.io, WebSockets |
| Job queues | BullMQ |
| AI integration | OpenAI, Pinecone vector search |
| Payments | Stripe |
| Logging | Winston, Pino, daily rotation |
| Validation | Zod, middleware |
| Containerization | Dockerfiles, multi-stage, slim images, healthchecks |
| Orchestration | Docker Compose (profiles, networking, limits), Swarm (replicas, rolling updates) |
| CI/CD | GitHub Actions, GHCR, image tagging |
| Reverse proxy | Nginx (rate limiting, DNS resolver for Swarm) |
| Frontend | Next.js, React, Tailwind, MUI, Chakra UI, Zustand |

### What's left

#### Testing & Quality
- Integration tests with test databases
- E2E tests (Playwright / Cypress)
- Load testing (k6, artillery)
- Memory profiling, leak detection (clinic.js)
- Benchmarking & bottleneck analysis

#### Databases & Data
- Query optimization & EXPLAIN plans
- Connection pooling (PgBouncer)
- Read replicas, sharding
- Migration strategies (zero-downtime)
- Event sourcing

#### System Design & Architecture
- **Outbox pattern** — reliable event publishing
- **Saga pattern** — distributed transactions across services
- **CQRS** — separate read/write models
- **Circuit Breaker, Bulkhead, Retry** — resilience patterns
- **Idempotency** — safe retries
- **Rate limiting at scale** — token bucket, sliding window

#### Microservices
- Service decomposition & communication (sync vs async)
- Event-driven (Kafka, RabbitMQ)
- Service discovery, API gateways
- Distributed tracing (OpenTelemetry + Jaeger)
- gRPC, GraphQL

#### Cloud & Infrastructure
- **Terraform / Pulumi** — infrastructure as code
- **Kubernetes** — pods, deployments, services, ingress (Swarm was step 1, K8s is step 2)
- **Helm** — package management for K8s
- **AWS** — ECS, RDS, ElastiCache, CloudFront, VPC design
- **Auto-scaling** — horizontal pod autoscaling, cluster autoscaler

#### Monitoring & Observability
- Metrics (Prometheus + Grafana dashboards)
- Centralized logging (ELK / Loki + Grafana)
- Distributed tracing (OpenTelemetry)
- Alerting (PagerDuty, OpsGenie)
- SLIs, SLOs, SLAs — measuring reliability

#### CI/CD & DevOps
- Multi-environment (dev/staging/prod)
- Blue-green & canary deployments
- Feature flags (LaunchDarkly, Unleash)
- GitOps (ArgoCD, Flux)
- Container registry management & image signing

#### Security
- OAuth2 / OIDC (Keycloak, Auth0)
- Secret rotation (Vault, AWS Secrets Manager)
- CSP, CORS hardening
- SQL injection & XSS prevention at scale
- Supply chain security (SBOM, container scanning)

#### Soft Skills (the senior differentiator)
- **ADRs** (Architecture Decision Records) — documenting why
- **Tech specs** — writing clear design documents
- **Code reviews** — reviewing with context, not just syntax
- **Incident response** — postmortems, runbooks
- **Mentoring** — helping others grow
- **Saying "no"** — pushing back on scope creep with data
