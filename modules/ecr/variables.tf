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

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}