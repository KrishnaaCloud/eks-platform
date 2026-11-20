terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region              = var.region
  allowed_account_ids = ["867344448097"]

  default_tags {
    tags = {
      project    = "eks-platform"
      managed_by = "terraform"
    }
  }
}
