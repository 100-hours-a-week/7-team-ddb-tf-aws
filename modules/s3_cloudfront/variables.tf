variable "env" {
  description = "대상 vpc 이름 (예: dev, prod)"
  type        = string
}

variable "bucket_name" {
  description = "S3 버킷 이름 (고유해야 함)"
  type        = string
}

variable "domain_name" {
  description = "CloudFront 도메인 (Route 53 또는 외부 도메인)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "CloudFront에서 사용할 ACM 인증서 ARN (us-east-1 리전)"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type        = map(string)
  default     = {}
}

variable "cors_origins" {
  description = "CORS 허용 origin 리스트"
  type        = list(string)
  default     = []
}