# orderflow

A small order-processing service built to learn Go and to serve as a portfolio
artifact for platform/SRE work. It grows in stages: a plain HTTP API first, then
PostgreSQL, Redis, and an SQS worker, then a full deployment on EKS with
autoscaling, GitOps, and SRE tooling.

## Status

- [x] HTTP API scaffold: config, structured logging, graceful shutdown, `/healthz`
- [ ] PostgreSQL + repository layer + migrations
- [ ] Idempotency keys on `POST /orders`
- [ ] Redis cache (stampede-protected)
- [ ] SQS worker pool with graceful shutdown
- [ ] Tests + docker-compose + load test

## Run

```bash
make run          # or: go run ./cmd/api
curl localhost:8080/healthz
# {"status":"ok"}
```

Configuration is read from the environment:

| Var         | Default | Notes                          |
|-------------|---------|--------------------------------|
| `PORT`      | `8080`  | HTTP listen port               |
| `LOG_LEVEL` | `info`  | `debug` / `info` / `warn` / `error` |

## Deploy on AWS

The `deploy/` directory runs the API on ECS Fargate behind an ALB. It uses
Terraform with staging and prod environments, and a GitHub Actions pipeline
that authenticates with OIDC. `make up ENV=staging` and
`make down ENV=staging` create and remove an environment. Setup, costs and
troubleshooting are in [deploy/README.md](deploy/README.md).

## Layout

```
cmd/api/            entrypoint (a cmd/worker/ will join it later)
internal/config/    environment-based configuration
internal/httpapi/   routes, handlers, middleware
```

## Design notes

Three trade-offs will be documented here as the service takes shape (idempotency
strategy, cache invalidation approach, and worker concurrency model).
