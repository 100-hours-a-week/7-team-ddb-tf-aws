variable "bucket_name" {
  description = "이 버킷의 이름"
  type        = string
}

variable "common_tags" {
  description = "공통으로 붙일 태그"
  type        = map(string)
  default     = {}
}