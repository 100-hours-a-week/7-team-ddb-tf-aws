variable "component" {
  description = "컴포넌트 이름 (예: fe, be)"
  type        = string
}

variable "env" {
  description = "환경 이름 (예: dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "port" {
  description = "서비스 포트"
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
  description = "공통 태그"
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
  description = "EC2가 배치될 서브넷 리스트"
  type        = list(string)
}

variable "alb_arn_suffix" {
  description = "ALB ARN Suffix"
  type        = string
}

variable "health_check_path" {
  description = "ALB에서 보낼 헬스 체크 HTTP 경로"
  type        = string
}

variable "health_check_period" {
  description = "헬스 체크 대기 시간"
  type        = number
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

variable "target_cpu_utilization" {
  description = "CPU 기반 오토스케일링 사용 시 목표 CPU 사용률 (%)"
  type        = number
  default     = null
}

variable "request_per_target_threshold" {
  description = "ALB 요청 수 기반 오토스케일링 사용 시 Target당 요청 수"
  type        = number
  default     = null
}

variable "additional_policy_arns" {
  description = "공통 IAM Role에 추가로 붙일 정책 ARN 목록"
  type    = list(string)
  default = []
}

variable "secret_arns" {
  description = "Secrets Manager 접근을 허용할 ARN 목록"
  type        = list(string)
  default     = []
}

variable "enable_blue_green" {
  description = "blue/green 적용 여부"
  type        = bool
  default     = false
}

variable "desired_capacity" {
  description = "Auto Scaling Group이 시작 시 유지할 인스턴스 수"
  type        = number
}

variable "min_size" {
  description = "Auto Scaling Group이 유지할 최소 인스턴스 수"
  type        = number
}

variable "max_size" {
  description = "Auto Scaling Group이 허용할 최대 인스턴스 수"
  type        = number
}

variable "allow_port" {
  description = "CIDR 별로 허용할 포트 리스트"
  type        = map(list(number))
}