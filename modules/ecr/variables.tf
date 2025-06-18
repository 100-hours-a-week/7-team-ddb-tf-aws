variable "env" {
  description = "배포 환경 (예: dev, prod)"
  type        = string
}

variable "name" {
  description = "ECR 리포지토리 이름"
  type        = string
}

variable "image_tag_mutability" {
  description = "태그 변경 가능 여부"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "푸시 시 이미지 자동 보안 스캔 여부"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "암호화 방식 (AES256 또는 KMS)"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "encryption_type은 'AES256' 또는 'KMS'여야 합니다."
  }
}

variable "kms_key" {
  description = "KMS 암호화 시 사용할 KMS Key ARN (encryption_type이 KMS일 경우 필수)"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "ECR 리포지토리에 적용할 IAM 정책(JSON 문자열)"
  type    = string
  default = null
}

variable "enable_lifecycle_policy" {
  description = "라이프사이클 정책 활성화 여부"
  type        = bool
  default     = true
}

variable "lifecycle_policy_rules" {
  description = "ECR 라이프사이클 정책 정의 목록"
  type = list(object({
    rulePriority = number
    description  = string
    tagStatus    = string
    countType    = string
    countUnit    = string
    countNumber  = number
    action_type  = string
  }))
  default = [
    {
      rulePriority = 1
      description  = "Expire untagged images after 10 days"
      tagStatus    = "untagged"
      countType    = "sinceImagePushed"
      countUnit    = "days"
      countNumber  = 10
      action_type  = "expire"
    }
  ]
}

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}