variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}

variable "domain_name" {
  description = "domain 이름"
  type = string
}

variable "subject_alternative_names" {
  description = "SAN 지정할 domain list"
  type    = list(string)
}