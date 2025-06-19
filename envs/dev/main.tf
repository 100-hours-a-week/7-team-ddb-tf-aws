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
    key          = "dev/terraform/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
# AWS Provider
provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "../../modules/network"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  common_tags     = var.common_tags
  env             = var.env
}

module "ecr_backend" {
  source = "../../modules/ecr"

  env                     = var.env
  name                    = var.be_ecr_name
  image_tag_mutability    = var.image_tag_mutability
  scan_on_push            = var.scan_on_push
  encryption_type         = var.encryption_type
}

module "ecr_frontend" {
  source = "../../modules/ecr"

  env                     = var.env
  name                    = var.fe_ecr_name
  image_tag_mutability    = var.image_tag_mutability
  scan_on_push            = var.scan_on_push
  encryption_type         = var.encryption_type
}