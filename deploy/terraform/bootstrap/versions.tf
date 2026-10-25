terraform {
  required_version = "~> 1.17"

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
