variable "env" {
  description = "대상 vpc 이름 (예: dev, prod)"
  type        = string
}

variable "bucket_name" {
  description = "S3 버킷 이름 (고유해야 함)"
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