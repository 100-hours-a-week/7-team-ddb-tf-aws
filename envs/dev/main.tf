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

module "shared_to_dev_peering" {
  source = "../../modules/vpc_peering"

  env                        = var.env
  component                  = "shared-to-dev"
  requester_vpc_id           = data.terraform_remote_state.shared.outputs.vpc_id
  accepter_vpc_id            = module.network.vpc_id
  requester_vpc_cidr         = data.terraform_remote_state.shared.outputs.vpc_cidr
  accepter_vpc_cidr          = var.vpc_cidr
  requester_route_table_ids  = data.terraform_remote_state.shared.outputs.private_route_table_ids
  accepter_route_table_ids   = module.network.private_route_table_ids
}