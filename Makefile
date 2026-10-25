.PHONY: run build test tidy check tf-bootstrap tf-init plan up down

# Start the API locally (defaults to :8080).
run:
	go run ./cmd/api

# Compile the api binary into ./bin.
build:
	go build -o bin/api ./cmd/api

test:
	go test ./...

tidy:
	go mod tidy

# ---- AWS deployment (see deploy/README.md) ----------------------------------

ENV       ?= staging
REGION    ?= ap-southeast-1
IMAGE_TAG ?= $(shell git rev-parse HEAD)

TF_DIR     := deploy/terraform
TF_ENV_DIR := $(TF_DIR)/envs/$(ENV)
TF_VARS    := -var region=$(REGION) -var image_tag=$(IMAGE_TAG)

# Every CI check, locally (go, docker, terraform fmt/validate, tflint, checkov).
check:
	scripts/check.sh

# One-time: state bucket + GitHub OIDC provider. Local state; keep it safe.
tf-bootstrap:
	terraform -chdir=$(TF_DIR)/bootstrap init -input=false
	terraform -chdir=$(TF_DIR)/bootstrap apply -var region=$(REGION)

tf-init:
	@case "$(ENV)" in staging|prod) ;; *) echo "ENV must be staging or prod (got '$(ENV)')"; exit 1;; esac
	@bucket=$$(terraform -chdir=$(TF_DIR)/bootstrap output -raw state_bucket 2>/dev/null); \
	if [ -z "$$bucket" ]; then echo "No state bucket found: run 'make tf-bootstrap' first."; exit 1; fi; \
	terraform -chdir=$(TF_ENV_DIR) init -input=false -reconfigure \
	  -backend-config="bucket=$$bucket" \
	  -backend-config="key=$(ENV)/terraform.tfstate" \
	  -backend-config="region=$(REGION)"

plan: tf-init
	terraform -chdir=$(TF_ENV_DIR) plan $(TF_VARS)

# Create the registry, push the image for the current commit, then the rest.
up: tf-init
	terraform -chdir=$(TF_ENV_DIR) apply $(TF_VARS) -target=module.ecr
	scripts/push-image.sh $(ENV) $(IMAGE_TAG) $(REGION)
	terraform -chdir=$(TF_ENV_DIR) apply $(TF_VARS)
	@terraform -chdir=$(TF_ENV_DIR) output url

# Destroy everything in the env, ECR images included (force_delete), so
# nothing keeps billing. The bootstrap bucket is kept on purpose.
down: tf-init
	terraform -chdir=$(TF_ENV_DIR) destroy $(TF_VARS)
