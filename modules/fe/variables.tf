variable "env" {
  description = "환경 이름 (예: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "fe_port" {
  description = "FE 애플리케이션 포트"
  type        = number
}

variable "alb_security_group_id" {
  description = "ALB의 Security Group ID"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}