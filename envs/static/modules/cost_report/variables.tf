variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
}

variable "env" {
  description = "환경"
  type        = string
}

variable "component" {
  description = "컴포넌트 이름"
  type        = string
}