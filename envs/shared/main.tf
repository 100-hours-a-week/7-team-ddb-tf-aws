terraform {
  required_version = "1.11.4"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.99.1"
    }
  }
  backend "s3" {
    bucket       = "dolpin-terraform-state-bn2gz7v3he1rj0ia"
    key          = "shared/terraform/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
# AWS Provider
provider "aws" {
  region = var.aws_region
}