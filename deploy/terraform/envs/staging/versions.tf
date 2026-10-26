terraform {
  # 1.10 is the oldest release this code supports: it added S3 native state
  # locking (use_lockfile). CI validates with 1.10.0 and the latest 1.x.
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.70"
    }
  }

  # Partial config: bucket, key and region are passed by `make` at init time
  # (from the bootstrap outputs), so no account-specific values live in git.
  backend "s3" {
    use_lockfile = true
    encrypt      = true
  }
}
