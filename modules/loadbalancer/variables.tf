variable "vpc_id" {
  description = "vpc id"
  type = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}

variable "public_subnet_ids" {
  description = "ALB에 사용할 Subnet ID"
  type        = list(string)
}

variable "cert_arn" {
  description = "lb에서 사용할 인증서"
  type = string
}