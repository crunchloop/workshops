terraform {
  required_version = ">= 1.5.7"

  backend "s3" {
    bucket  = "terraform-crunchloop-aws"
    key     = "apps-workshops.tfstate"
    region  = "us-east-1"
    profile = "crunchloop"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20"
    }
  }
}

locals {
  aws_region  = "sa-east-1"
  github_repo = "crunchloop/workshops"
}

provider "aws" {
  region  = local.aws_region
  profile = "crunchloop"

  allowed_account_ids = [
    "176434290504"
  ]

  default_tags {
    tags = {
      Terraform   = "true"
      Application = "workshops"
      Environment = "dev"
    }
  }
}

# Remote state: EKS cluster (for OIDC provider)
data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "terraform-crunchloop-aws"
    key    = "crunchloop-k8-dev.tfstate"
    region = "us-east-1"
  }
}

# AWS caller identity
data "aws_caller_identity" "current" {}
