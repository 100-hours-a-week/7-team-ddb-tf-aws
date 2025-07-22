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

module "cost_report" {
  source                   = "./modules/cost_report"
  schedule_expression_cron = "cron(5 9 * * ? *)"
  common_tags              = var.common_tags
  env                      = var.env
  component                = "cr"
}

module "tf_automation" {
  source           = "./modules/tf_automation"
  common_tags      = var.common_tags
  env              = var.env
  component        = "ta"
  lambda_schedules = var.lambda_schedules
  asg_config = var.asg_config
}

module "codedeploy_asg_hook" {
  source           = "./modules/cd_asg_hook"
  common_tags      = var.common_tags
  env              = var.env
  component        = "cdhook"
}