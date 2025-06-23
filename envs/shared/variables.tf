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
    tool-a = {
      cidr                    = "10.30.1.0/24"
      az                      = "ap-northeast-2a"
      map_public_ip_on_launch = true
    }
    tool-b = {
      cidr                    = "10.30.2.0/24"
      az                      = "ap-northeast-2c"
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

variable "domain_name" {
  description = "환경"
  type        = string
  default     = "shared.dolpin.site"
}

variable "domain_zone_name" {
  description = "환경"
  type        = string
  default     = "dolpin.site"
}

variable "domain_wildcard" {
  description = "도메인 인증서 와일드 카드"
  type        = string
  default     = "*.shared.dolpin.site"
}

variable "nat_azs" {
  description = "NAT Gateway를 배치할 AZ 목록"
  type        = list(string)
  default     = ["ap-northeast-2a"]
}