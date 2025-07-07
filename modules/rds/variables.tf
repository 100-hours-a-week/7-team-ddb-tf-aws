variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "db_subnet_ids" {
  description = "DB에 사용할 Subnet ID 리스트"
  type        = list(string)
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}

variable "env" {
  description = "환경"
  type = string
}

variable "allow_sg_list" {
  description = "db에 접근 가능한 sg-id 리스트"
  type = list(string)
}

variable "allow_cidr_block_list" {
  description = "db에 접근 가능한 cidr block 리스트"
  type = list(string)
}

variable "db_engine" {
  description = "database engine 종류 (ex: mysql, postgres 등)"
  type = string
}

variable "db_engine_version" {
  description = "database engine 버전"
  type = string
}

variable "db_instance_class" {
  description = "database instance class (ex: db.t3.micro)"
  type = string
}

variable "db_multi_az" {
  description = "db가 multi az 지원 여부"
  type = bool
}

variable "db_backup_retention_period" {
  description = "자동 백업 보관 기간 (일 단위, 최소 0일 ~ 최대 35일)"
  type = string
}

variable "db_backup_window" {
  description = "자동 백업이 수행될 선호 시간대 (UTC 기준)"
  type = string
}