variable "vpc_id" {
  description = "Redis VPC ID"
  type        = string
}

variable "redis_subnet_ids" {
  description = "Redis에 사용할 프라이빗 서브넷 ID 리스트"
  type        = list(string)
}

variable "allowed_cidrs" {
  description = "Redis 접근 허용 CIDR 리스트"
  type        = list(string)
}

variable "allow_sg_list" {
  description = "Redis 접근 허용 sg-id 리스트"
  type = list(string)
}

variable "redis_prefix" {
  description = "Redis group 이름 prefix"
  type        = string
}

variable "redis_engine_version" {
  description = "Redis 엔진 버전"
  type        = string
}

variable "node_type" {
  description = "Redis 인스턴스 노드 타입"
  type        = string
}

variable "cache_clusters" {
  description = "Redis 클러스터의 캐시 노드 수 (primary + replica 개수)"
  type        = number
}

variable "parameter_group_name" {
  description = "Redis 파라미터 그룹 이름"
  type        = string
}

variable "snapshot_retention_limit" {
  description = "유지할 snapshot 개수"
  type        = number
}

variable "env" {
  description = "환경"
  type        = string
}

variable "common_tags" {
  description = "기본 태그"
  type = map(string)
}