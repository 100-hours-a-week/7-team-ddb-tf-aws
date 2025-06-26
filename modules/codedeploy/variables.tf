variable "name_prefix" {
  description = "리소스 이름 접두어 (예: fe-dev)"
  type        = string
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}
