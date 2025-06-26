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
    key          = "static/terraform/terraform.tfstate"
    region       = "ap-northeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
# AWS Provider
provider "aws" {
  region = var.aws_region
}

module "acm_validation" {
  source                    = "../../modules/acm_validation"
  common_tags               = var.common_tags
  env                       = var.env
  domain_name               = "boamoa.shop"
  subject_alternative_names = ["*.boamoa.shop", "*.dev.boamoa.shop"]
}

module "cost_report" {
  source                   = "./modules/cost_report"
  schedule_expression_cron = "cron(0 9 * * ? *)"
  common_tags              = var.common_tags
  env                      = var.env
  component                = "cr"
}
