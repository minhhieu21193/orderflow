provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project   = var.project
      Env       = "global"
      Owner     = var.owner
      ManagedBy = "terraform"
    }
  }
}
