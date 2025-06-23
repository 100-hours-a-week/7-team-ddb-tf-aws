variable "role_name" {
  description = "IAM Role 이름"
  type        = string
}

variable "attach_ecr" {
  description = "ECR 권한을 부여할지 여부"
  type        = bool
  default     = false
}

variable "attach_s3" {
  description = "S3 접근 권한을 부여할지 여부"
  type        = bool
  default     = false
}
