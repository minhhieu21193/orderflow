terraform {
  required_version = "~> 1.17"

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
