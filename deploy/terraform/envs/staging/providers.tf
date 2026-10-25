provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Env       = local.env
      Owner     = var.owner
      ManagedBy = "terraform"
    }
  }
}
