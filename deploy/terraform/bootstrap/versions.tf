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

  # Local state on purpose: this root creates the remote state bucket.
  # Keep terraform.tfstate safe (it is gitignored) or migrate it into the
  # bucket afterwards — see deploy/README.md.
}
