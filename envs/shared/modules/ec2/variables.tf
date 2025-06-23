variable "name" {
  description = "이 인스턴스의 이름"
  type        = string
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "subnet_id" {
  description = "이 인스턴스가 속할 서브넷 ID"
  type        = string
}

variable "vpc_id" {
  description = "보안 그룹용 VPC ID"
  type        = string
}

variable "user_data" {
  description = "User data script"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 30
}

variable "name_prefix" {
  description = "리소스 이름에 사용할 접두사"
  type        = string
}

variable "ingress_rules" {
  description = "각 포트별 ingress 접근 허용 규칙 (CIDR 또는 SG ID)"
  type = list(object({
    port                    = number
    cidrs                   = optional(list(string), [])
    source_security_group_ids = optional(list(string), [])
  }))
}
