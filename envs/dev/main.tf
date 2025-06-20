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
  source          = "../../modules/network"
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
  requester_route_table_ids = {
    default = data.terraform_remote_state.shared.outputs.private_route_table_ids["ap-northeast-2a"]
  }
  accepter_route_table_ids = {
    default = module.network.private_route_table_ids["ap-northeast-2a"]
  }
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
  domains_alias = {}
  domains_records = {}
}

module "rds" {
  source                = "../../modules/rds"
  vpc_id                = module.network.vpc_id
  db_subnet_ids         = module.network.db_subnet_ids
  common_tags           = var.common_tags
  env                   = var.env
  allow_sg_list         = []
  allow_cidr_block_list = []
  db_engine             = var.db_engine
  db_engine_version     = var.db_engine_version
  db_instance_class     = var.db_instance_class
  db_multi_az           = var.db_multi_az
}
