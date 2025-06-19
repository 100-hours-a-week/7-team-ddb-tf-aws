variable "domain_zone_name" {
  description = "서비스 도메인 zone 이름"
  type        = string
}

variable "domains_alias" {
  description = "도메인 별칭"
  type = map(object({
    domain_name   = string
    alias_name    = string
    alias_zone_id = string
  }))
}
variable "domains_records" {
  description = "도메인 레코드"
  type = map(object({
    domain_name = string
    records     = list(string)
  }))
}
