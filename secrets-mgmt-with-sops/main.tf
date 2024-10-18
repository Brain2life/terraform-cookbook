terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "sops" {}
