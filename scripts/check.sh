#!/usr/bin/env bash
# Runs the same checks as CI, locally. Never needs AWS credentials:
# Terraform is initialised with -backend=false and nothing is planned or applied.
#
#   scripts/check.sh            # everything
#   SKIP_DOCKER=1 scripts/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

TF_ROOT=deploy/terraform
IMAGE=orderflow:check
MAX_IMAGE_MB=25

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

step "go vet / go test"
go vet ./...
go test ./...

if [[ -z "${SKIP_DOCKER:-}" ]]; then
  step "docker build"
  docker build -q -t "$IMAGE" . >/dev/null

  size_mb=$(( $(docker image inspect -f '{{.Size}}' "$IMAGE") / 1024 / 1024 ))
  echo "image size: ${size_mb} MB"
  (( size_mb < MAX_IMAGE_MB )) || { echo "image is ${size_mb} MB, limit ${MAX_IMAGE_MB} MB"; exit 1; }

  step "container smoke test"
  cid=$(docker run -d --rm --read-only -p 127.0.0.1::8080 "$IMAGE")
  trap 'docker rm -f "$cid" >/dev/null 2>&1 || true' EXIT
  port=$(docker port "$cid" 8080/tcp | head -1 | cut -d: -f2)
  for path in /healthz /readyz; do
    curl -fsS --retry 10 --retry-all-errors --retry-delay 1 "http://127.0.0.1:${port}${path}"
    echo "  <- ${path}"
  done
fi

command -v hadolint >/dev/null && { step "hadolint"; hadolint Dockerfile; }
if command -v actionlint >/dev/null && [[ -d .github/workflows ]]; then
  step "actionlint"; actionlint
fi

[[ -d "$TF_ROOT" ]] || exit 0

step "terraform fmt"
terraform fmt -check -recursive "$TF_ROOT"

step "tflint (all modules and roots)"
tflint --init --config "$PWD/$TF_ROOT/.tflint.hcl" >/dev/null
tflint --recursive --chdir="$TF_ROOT" --config "$PWD/$TF_ROOT/.tflint.hcl"

for dir in "$TF_ROOT"/bootstrap "$TF_ROOT"/envs/*; do
  [[ -d "$dir" ]] || continue
  step "terraform validate: $dir"
  terraform -chdir="$dir" init -backend=false -input=false -no-color >/dev/null
  terraform -chdir="$dir" validate -no-color

  step "checkov: $dir"
  checkov -d "$dir" --config-file "$TF_ROOT/.checkov.yaml"
done

step "all checks passed"
