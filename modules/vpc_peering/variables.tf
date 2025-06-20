variable "env" {
  description = "대상 vpc 이름 (예: dev, prod)"
  type        = string
}

variable "component" {
  description = "논리적 peering 명 (예: shared-to-dev)"
  type        = string
}

variable "requester_vpc_id" {
  description = "Peering 요청 VPC ID"
  type        = string
}

variable "accepter_vpc_id" {
  description = "Peering 수락 VPC ID"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "요청 VPC의 CIDR 블록"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "수락 VPC의 CIDR 블록"
  type        = string
}

variable "auto_accept" {
  description = "같은 계정/리전이면 true, cross-account면 false"
  type        = bool
  default     = true
}

variable "requester_route_table_ids" {
  description = "shared VPC의 route table id 목록 (cicd, monitoring 등)"
  type        = map(string)
}

variable "accepter_route_table_ids" {
  description = "dev 또는 prod VPC의 route table id 목록 (fe, be, db 등)"
  type        = map(string)
}