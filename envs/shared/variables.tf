variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnets" {
  description = "public subnet 정보"
  type = map(object({
    cidr                    = string
    az                      = string
    map_public_ip_on_launch = bool
  }))
  default = {
    tool = {
      cidr                    = "10.30.1.0/24"
      az                      = "ap-northeast-2a"
      map_public_ip_on_launch = true
    }
  }
}

variable "private_subnets" {
  description = "private subnet 정보"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    cicd = {
      cidr = "10.30.10.0/24"
      az   = "ap-northeast-2a"
    },
    monitoring = {
      cidr = "10.30.110.0/24"
      az   = "ap-northeast-2a"
    }
  }
}
variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "shared"
    Owner       = "dolpin"
  }
}

variable "env" {
  description = "환경"
  type        = string
  default     = "shared"
}

variable "domain_zone_name" {
  description = "환경"
  type        = string
  default     = "dolpin.site"
}

variable "nat_azs" {
  description = "NAT Gateway를 배치할 AZ 목록"
  type        = list(string)
  default     = ["ap-northeast-2a"]
}

variable "ami_id" {
  description = "jenkins, monitoring instance type"
  type        = string
  default     = "ami-08943a151bd468f4e"
}

variable "jenkins_instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "jenkins_ingress_rules" {
  description = "각 포트별 ingress 접근 허용 규칙 (CIDR 또는 SG ID)"
  type = list(object({
    port                      = number
    cidrs                     = optional(list(string), [])
    source_security_group_ids = optional(list(string), [])
  }))
  default = [
    {
      port  = 443
      cidrs = ["0.0.0.0/0"]
    },
    {
      port  = 9090
      cidrs = ["0.0.0.0/0"]
    }
  ]
}

variable "monitoring_instance_type" {
  type        = string
  default     = "t3.medium"
}

variable "monitoring_ingress_rules" {
  description = "각 포트별 ingress 접근 허용 규칙 (CIDR 또는 SG ID)"
  type = list(object({
    port                      = number
    cidrs                     = optional(list(string), [])
    source_security_group_ids = optional(list(string), [])
  }))
  default = [
    {
      port  = 443
      cidrs = ["0.0.0.0/0"]
    }
  ]
}

variable "jenkins_port" {
  description = "Jenkins 서비스 포트"
  type        = number
  default     = 9090
}

variable "jenkins_health_check_path" {
  description = "Jenkins 인스턴스의 Health Check 경로"
  type        = string
  default     = "/login"
}

variable "jenkins_path" {
  description = "ALB에서 Jenkins로 포워딩할 Path 패턴"
  type        = list(string)
  default     = ["/jenkins*"]
}

variable "jenkins_listener_rule_priority" {
  description = "Jenkins ALB Listener Rule의 우선순위"
  type        = number
  default     = 100
}

variable "monitoring_port" {
  description = "Monitoring 서비스 포트"
  type        = number
  default     = 3000
}

variable "monitoring_health_check_path" {
  description = "Monitoring 인스턴스의 Health Check 경로"
  type        = string
  default     = "/api/health"
}

variable "monitoring_path" {
  description = "ALB에서 Monitoring으로 포워딩할 Path 패턴"
  type        = list(string)
  default     = ["/monitoring*"]
}

variable "monitoring_listener_rule_priority" {
  description = "Monitoring ALB Listener Rule의 우선순위"
  type        = number
  default     = 110
}