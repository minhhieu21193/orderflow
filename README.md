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

## Layout

```
cmd/api/            entrypoint (a cmd/worker/ will join it later)
internal/config/    environment-based configuration
internal/httpapi/   routes, handlers, middleware
```

## Design notes

Three trade-offs will be documented here as the service takes shape (idempotency
strategy, cache invalidation approach, and worker concurrency model).
