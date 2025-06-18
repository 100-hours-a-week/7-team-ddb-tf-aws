variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "key: subnet 이름. value: 정보 리스트"
  type = map(object({
    cidr                    = string
    az                      = string
    map_public_ip_on_launch = bool
  }))
}

variable "private_subnets" {
  description = "key: subnet 이름. value: 정보 리스트"
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}