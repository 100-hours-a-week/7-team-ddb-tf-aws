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
  cert_arn          = module.acm_seoul.cert_arn
  common_tags       = var.common_tags
  env               = var.env
}

module "route53" {
  source = "../../modules/route53"
  domain_zone_name = var.domain_zone_name
  domains_alias = {
    "${var.jenkins_alias_name}" = {
      domain_name   = var.jenkins_alias_name
      alias_name    = module.loadbalancer.alb_dns_name
      alias_zone_id = module.loadbalancer.alb_zone_id
    }
    "${var.monitoring_alias_name}" = {
      domain_name   = var.monitoring_alias_name
      alias_name    = module.loadbalancer.alb_dns_name
      alias_zone_id = module.loadbalancer.alb_zone_id
    }
  }
  domains_records = {}
}

module "jenkins_instance" {
  source                    = "./modules/ec2"
  name_prefix               = "shared"
  name                      = "jenkins"
  instance_type             = var.jenkins_instance_type
  ami_id                    = var.ami_id
  subnet_id                 = module.network.private_subnet_ids["cicd"]
  vpc_id                    = module.network.vpc_id
  user_data                 = base64encode(templatefile("${path.module}/scripts/startup_jenkins.sh.tpl", {
    dockerfile_content    = file("${path.module}/files/Dockerfile.jenkins")
    dockercompose_content = file("${path.module}/files/docker-compose.yml")
  }))
  ingress_rules             = var.jenkins_ingress_rules
  common_tags               = var.common_tags
  iam_instance_profile_name = module.iam_jenkins.instance_profile_name
  app_port                  = var.jenkins_port
  health_check_path         = var.jenkins_health_check_path
  https_listener_arn        = module.loadbalancer.https_listener_arn
  listener_rule_priority    = var.jenkins_listener_rule_priority
  host_header_values = [var.jenkins_alias_name]
}

module "iam_jenkins" {
  source      = "./modules/iam/jenkins"
  role_name   = "jenkins"
}

module "acm_seoul" {
  providers                 = { aws = aws.seoul }
  source                    = "../../modules/acm"
  common_tags               = var.common_tags
  env                       = var.env
  domain_name               = var.domain_name
  domain_zone_name = var.domain_zone_name
  subject_alternative_names = [var.domain_wildcard]
}

module "loki_backup" {
  source      = "./modules/s3"
  bucket_name = "loki-backup-bn2gz7v3he1rj0ia"
}

module "thanos_backup" {
  source = "./modules/s3"
  bucket_name = "thanos-backup-bn2gz7v3he1rj0ia"
}

module "monitoring_iam" {
  source     = "./modules/iam/monitoring"
  s3_buckets = local.s3_buckets
  role_name  = "monitoring"
}

module "monitoring_instance" {
  source                    = "./modules/ec2"
  name_prefix               = "shared"
  name                      = "monitoring"
  instance_type             = var.monitoring_instance_type
  ami_id                    = var.ami_id
  subnet_id                 = module.network.private_subnet_ids["monitoring"]
  vpc_id                    = module.network.vpc_id
  user_data                 = base64encode(file("${path.module}/monitoring/script/startup.sh"))
  ingress_rules             = var.monitoring_ingress_rules
  common_tags               = var.common_tags
  iam_instance_profile_name = module.monitoring_iam.instance_profile_name
  app_port                  = var.monitoring_port
  health_check_path         = var.monitoring_health_check_path
  https_listener_arn        = module.loadbalancer.https_listener_arn
  listener_rule_priority    = var.monitoring_listener_rule_priority
  host_header_values = [var.monitoring_alias_name]
}
