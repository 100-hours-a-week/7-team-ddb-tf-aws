variable "env" {
  description = "환경 이름 (예: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "be_port" {
  description = "BE 애플리케이션 포트"
  type        = number
}

variable "alb_security_group_id" {
  description = "ALB의 Security Group ID"
  type        = string
}

variable "allowed_cidrs" {
  description = "허용할 CIDR 리스트 (VPC Peering 등)"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}

variable "ami_id" {
  description = "EC2 AMI ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "subnet_ids" {
  description = "BE가 배치될 서브넷 리스트"
  type        = list(string)
}

variable "alb_arn_suffix" {
  description = "ALB ARN Suffix"
  type        = string
}

variable "target_cpu_utilization" {
  description = "목표 CPU 사용률 (%)"
  type        = number
  default     = 60
}

variable "health_check_path" {
  description = "ALB에서 BE로 보낼 헬스 체크 HTTP 경로"
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