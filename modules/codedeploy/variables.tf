variable "name_prefix" {
  description = "리소스 이름 접두어 (예: fe-dev)"
  type        = string
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}

variable "autoscaling_group_name" {
  description = "ASG 이름"
  type        = string
}

variable "deployment_config_name" {
  description = "배포 구성 이름"
  type        = string
}

variable "instance_name" {
  description = "EC2 인스턴스 태그 Name 값"
  type        = string
}

variable "alb_listener_arn" {
  description = "트래픽 전환을 위한 ALB Listener ARN"
  type        = string
}

variable "blue_target_group_name" {
  description = "blue target group 이름"
  type        = string
}

variable "green_target_group_name" {
  description = "green target group 이름"
  type        = string
}

variable "enable_blue_green" {
  description = "Blue/Green 배포 여부"
  type        = bool
}