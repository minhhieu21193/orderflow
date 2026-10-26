#!/usr/bin/env bash
# Build the API image and push it to an env's ECR repository, tagged with
# the git SHA. Used by `make up`; CI pushes through deploy.yml instead.
#
#   scripts/push-image.sh <env> <tag> <region>
set -euo pipefail
cd "$(dirname "$0")/.."

env=$1 tag=$2 region=$3
repo_url=$(terraform -chdir="deploy/terraform/envs/$env" output -raw ecr_repository_url)
registry=${repo_url%%/*}
repo=${repo_url#*/}

# Tags are immutable in ECR: an existing tag already holds this commit's image.
if aws ecr describe-images --region "$region" --repository-name "$repo" \
     --image-ids imageTag="$tag" >/dev/null 2>&1; then
  echo "image $repo:$tag already in ECR, skipping build"
  exit 0
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "warning: uncommitted changes are included in the image tagged $tag" >&2
fi

aws ecr get-login-password --region "$region" |
  docker login --username AWS --password-stdin "$registry"

# The task definition runs X86_64; the Dockerfile cross-compiles, so this
# needs no emulation on an arm64 laptop.
docker buildx build --platform linux/amd64 --provenance=false \
  -t "$repo_url:$tag" --push .
