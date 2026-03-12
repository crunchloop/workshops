terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "terraform-crunchloop-aws"
    key     = "apps-workshops.tfstate"
    region  = "us-east-1"
    profile = "crunchloop"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  github_repo      = "crunchloop/workshops"
  account_id       = data.aws_caller_identity.current.account_id
  region           = data.aws_region.current.name
  eks_cluster_name = data.terraform_remote_state.eks.outputs.cluster_name
  oidc_issuer      = replace(data.terraform_remote_state.eks.outputs.oidc_provider_arn, "/^(.*provider/)/", "")
}

provider "aws" {
  region  = "sa-east-1"
  profile = "development"

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

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket  = "terraform-crunchloop-aws"
    key     = "crunchloop-k8-dev.tfstate"
    region  = "us-east-1"
    profile = "crunchloop"
  }
}
