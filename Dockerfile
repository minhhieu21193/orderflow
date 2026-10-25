# syntax=docker/dockerfile:1

# ---- build: static Go binary ----------------------------------------------
# Runs on the build host's platform and cross-compiles for the target, so
# `docker buildx build --platform linux/arm64` works without emulation.
FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24@sha256:b8c9b82affbbb82a020bbcf998dad2ba9516944ac7e883524642a481a9505e9c AS build

WORKDIR /src

# Dependencies first so this layer stays cached until go.mod/go.sum change.
COPY go.* ./
RUN go mod download

COPY . .

ARG TARGETOS=linux
ARG TARGETARCH=amd64
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/api ./cmd/api

# ---- runtime: distroless, non-root, no shell --------------------------------
# No HEALTHCHECK on purpose: the ALB target group health check (/readyz) owns
# liveness in ECS, and distroless has no shell or curl to run one anyway.
FROM gcr.io/distroless/static-debian13:nonroot@sha256:18f4cc26c9ffa7f20a359298be7deadac5c607c8e03a02b8119f1a5fc2f82c99

COPY --from=build /out/api /api

ENV PORT=8080
EXPOSE 8080
# 65532 is the distroless "nonroot" user; numeric so runtimes can verify it.
USER 65532:65532

ENTRYPOINT ["/api"]
