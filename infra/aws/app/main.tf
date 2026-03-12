terraform {
  backend "s3" {
    bucket = "crunchloop-terraform-state"
    key    = "workshops/app/terraform.tfstate"
    region = "sa-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "crunchloop-terraform-state"
    key    = "crunchloop-vpc-dev/terraform.tfstate"
    region = "sa-east-1"
  }
}

data "aws_eks_cluster" "k8_dev" {
  name = var.eks_cluster_name
}
