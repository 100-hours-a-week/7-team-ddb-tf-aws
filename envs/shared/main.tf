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

module "network" {
  source = "../../modules/network"
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  common_tags     = var.common_tags
  env             = var.env
}

module "loadbalancer" {
  source            = "../../modules/loadbalancer"
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  cert_arn          = ""
  common_tags       = var.common_tags
  env               = var.env
}

module "route53" {
  source = "../../modules/route53"
  domain_zone_name = var.domain_zone_name
  domains_alias = []
  domains_records = []
}
