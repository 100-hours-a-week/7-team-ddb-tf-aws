variable "env" {
  description = "환경 이름 (예: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
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

variable "subnet_ids" {
  description = "FE가 배치될 서브넷 리스트"
  type        = list(string)
}

variable "alb_arn_suffix" {
  description = "ALB ARN Suffix"
  type        = string
}

variable "request_per_target_threshold" {
  description = "Target 하나당 초당 요청 수 목표치"
  type        = number
  default     = 50
}

variable "health_check_path" {
  description = "ALB에서 FE로 보낼 헬스 체크 HTTP 경로"
  type        = string
}

variable "alb_listener_arn_https" {
  description = "HTTPS Listener ARN"
  type        = string
}

variable "listener_rule_priority" {
  description = "ALB Listener Rule에서 사용할 우선순위"
  type        = number
}

variable "host_header_values" {
  description = "ALB Listener Rule 조건에 사용할 host_header 값 리스트"
  type        = list(string)
}

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}