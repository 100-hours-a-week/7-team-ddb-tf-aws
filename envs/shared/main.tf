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
  nat_azs         = var.nat_azs
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

module "jenkins_instance" {
  source         = "./modules/ec2"
  name_prefix    = "shared"
  name           = "jenkins"
  instance_type  = var.jenkins_instance_type
  ami_id         = var.ami_id
  subnet_id      = module.network.private_subnet_ids["cicd"]
  vpc_id         = module.network.vpc_id
  user_data      = filebase64("${path.module}/scripts/startup_jenkins.sh")
  ingress_rules  = var.jenkins_ingress_rules
  common_tags    = var.common_tags
  iam_instance_profile_name = module.iam_jenkins.instance_profile_name
}

module "iam_jenkins" {
  source      = "./modules/iam/jenkins"
  role_name   = "jenkins"
}

module "monitoring_instance" {
  source         = "./modules/ec2"
  name_prefix    = "shared"
  name           = "monitoring"
  instance_type  = var.monitoring_instance_type
  ami_id         = var.ami_id
  subnet_id      = module.network.private_subnet_ids["monitoring"]
  vpc_id         = module.network.vpc_id
  user_data      = filebase64("${path.module}/scripts/startup_monitoring.sh")
  ingress_rules  = var.monitoring_ingress_rules
  common_tags    = var.common_tags
  iam_instance_profile_name = module.iam_monitoring.instance_profile_name
}

module "iam_monitoring" {
  source      = "./modules/iam/monitoring" 
  role_name   = "monitoring"
}