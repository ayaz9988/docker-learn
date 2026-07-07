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

## Projects

| Project | Stack | Notes |
|---------|-------|-------|
| backend_complaints_block_5 | Express 5, Prisma, PostgreSQL, Zod, JWT, Docker | Personal |
| job-board | Express 5, Drizzle, PostgreSQL, better-auth, Zod, Winston | Personal |
| virtualoffice | Express 4, React, SQLite, Zustand, Zoom SDK | Personal |
| docker-learn | Express 4, SQLite, Redis, Docker, Swarm | Personal |
| lms-portal-backend | Express 4, PostgreSQL, Socket.io, BullMQ, OpenAI, Stripe | Contributing — reports/students features, caching, notifications |
| lms-portal-interface | Next.js 14, React, Tailwind, MUI | Contributing — student reports UI, filters, routing, fixes |
| aws-s3-signed-urls | TypeScript, AWS SDK v3 | Learning |
| cloudinary-signed-urls | TypeScript, Cloudinary SDK | Learning |

## Path to senior backend

### Already covered

| Area | What I've done |
|------|---------------|
| REST APIs | Express 4/5, routing, middleware, error handling |
| Databases | SQLite, PostgreSQL, Prisma, Drizzle, raw SQL |
| Caching | Redis, ioredis, cache invalidation |
| Auth | JWT, better-auth, session management |
| File uploads | Multer |
| Real-time | Socket.io, WebSockets |
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
- **Job/Message queues** — BullMQ, Kafka, RabbitMQ
- **AI integration** — OpenAI, Pinecone, vector search patterns

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
- **S3 presigned URLs** — secure file uploads/downloads
- **Cloudinary signed URLs** — media uploads
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

#### Payments
- Stripe — checkout sessions, subscriptions, webhooks, invoicing (not available in Syria)

#### Security
- OAuth2 / OIDC (Keycloak, Auth0)
- OTP / verification codes
- Secret rotation (Vault, AWS Secrets Manager)
- CSP, CORS hardening
- SQL injection & XSS prevention at scale
- Supply chain security (SBOM, container scanning)
