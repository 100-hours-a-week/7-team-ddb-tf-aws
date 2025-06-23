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
    key          = "prod/terraform/terraform.tfstate"
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
  nat_azs         = var.nat_azs
}

module "shared_to_prod_peering" {
  source = "../../modules/vpc_peering"

  env                        = var.env
  component                  = "shared-to-prod"
  requester_vpc_id           = data.terraform_remote_state.shared.outputs.vpc_id
  accepter_vpc_id            = module.network.vpc_id
  requester_vpc_cidr         = data.terraform_remote_state.shared.outputs.vpc_cidr
  accepter_vpc_cidr          = var.vpc_cidr
  requester_route_table_ids = {
    "ap-northeast-2a" = data.terraform_remote_state.shared.outputs.private_route_table_ids["ap-northeast-2a"]
  }
  accepter_route_table_ids  = module.network.private_route_table_ids
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
  cert_arn          = module.acm_seoul.cert_arn
  common_tags       = var.common_tags
  env               = var.env
}
        
module "route53" {
  source = "../../modules/route53"
  domain_zone_name = var.domain_zone_name
  domains_alias = {
    "${var.fe_alias_name}" = {
      domain_name   = var.fe_alias_name
      alias_name    = module.loadbalancer.alb_dns_name
      alias_zone_id = module.loadbalancer.alb_zone_id
    },
    "${var.be_alias_name}" = {
      domain_name   = var.be_alias_name
      alias_name    = module.loadbalancer.alb_dns_name
      alias_zone_id = module.loadbalancer.alb_zone_id
    }
  }
  domains_records = {}
}        

module "rds" {
  source = "../../modules/rds"
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

module "fe" {
  source                       = "../../modules/asg"
  component                    = "fe"
  env                          = var.env
  vpc_id                       = module.network.vpc_id
  port                         = var.fe_port
  subnet_ids                   = local.fe_subnet_ids
  ami_id                       = var.fe_ami_id
  instance_type                = var.fe_instance_type
  common_tags                  = var.common_tags
  alb_security_group_id        = module.loadbalancer.alb_sg_id
  alb_listener_arn_https       = module.loadbalancer.https_listener_arn
  alb_arn_suffix               = module.loadbalancer.alb_arn_suffix
  listener_rule_priority       = var.fe_listener_rule_priority
  host_header_values           = var.fe_host_header_values
  request_per_target_threshold = var.fe_request_per_target_threshold
  health_check_path            = var.fe_health_check_path
  allowed_cidrs                = var.fe_allowed_cidrs
}

module "be" {
  source                   = "../../modules/asg"
  component                = "be"
  env                      = var.env
  vpc_id                   = module.network.vpc_id
  port                     = var.be_port
  subnet_ids               = local.be_subnet_ids
  ami_id                   = var.be_ami_id
  instance_type            = var.be_instance_type
  common_tags              = var.common_tags
  alb_security_group_id    = module.loadbalancer.alb_sg_id
  alb_listener_arn_https   = module.loadbalancer.https_listener_arn
  alb_arn_suffix           = module.loadbalancer.alb_arn_suffix
  listener_rule_priority   = var.be_listener_rule_priority
  host_header_values       = var.be_host_header_values
  target_cpu_utilization   = var.be_target_cpu_utilization
  health_check_path        = var.be_health_check_path
  allowed_cidrs            = var.be_allowed_cidrs
}

module "acm_seoul" {
  providers                 = { aws = aws.seoul }
  source                    = "../../modules/acm"
  common_tags               = var.common_tags
  env                       = var.env
  domain_zone_name          = var.domain_zone_name
  domain_name               = var.domain_name
  subject_alternative_names = [var.domain_wildcard]
}

module "acm_nova" {
  providers                 = { aws = aws.nova }
  source                    = "../../modules/acm"
  common_tags               = var.common_tags
  env                       = var.env
  domain_zone_name          = var.domain_zone_name
  domain_name               = var.domain_name
  subject_alternative_names = [var.domain_wildcard]
}
