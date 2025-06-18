variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.20.0.0/16"
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
      cidr                    = "10.20.1.0/24"
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
    fe = {
      cidr = "10.20.10.0/24"
      az   = "ap-northeast-2a"
    }
    be = {
      cidr = "10.20.110.0/24"
      az   = "ap-northeast-2a"
    }
    db = {
      cidr = "10.20.210.0/24"
      az   = "ap-northeast-2a"
    }
  }
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "dev"
    Owner       = "dolpin"
  }
}

variable "env" {
  description = "환경"
  type        = string
  default     = "dev"
}
