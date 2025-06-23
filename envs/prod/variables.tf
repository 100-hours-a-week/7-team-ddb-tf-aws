variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnets" {
  description = "public subnet 정보"
  type = map(object({
    cidr                    = string
    az                      = string
    map_public_ip_on_launch = bool
  }))
  default = {
    tool-a = {
      cidr                    = "10.10.1.0/24"
      az                      = "ap-northeast-2a"
      map_public_ip_on_launch = true
    },
    tool-b = {
      cidr                    = "10.10.2.0/24"
      az                      = "ap-northeast-2c"
      map_public_ip_on_launch = true
    },
  }
}

variable "private_subnets" {
  description = "private subnet 정보"
  type = map(object({
    cidr = string
    az   = string
  }))
  default = {
    fe-a = {
      cidr = "10.10.10.0/24"
      az   = "ap-northeast-2a"
    },
    fe-b = {
      cidr = "10.10.20.0/24"
      az   = "ap-northeast-2c"
    },
    be-a = {
      cidr = "10.10.110.0/24"
      az   = "ap-northeast-2a"
    },
    be-b = {
      cidr = "10.10.120.0/24"
      az   = "ap-northeast-2c"
    },
    db-a = {
      cidr = "10.10.210.0/24"
      az   = "ap-northeast-2a"
    },
    db-b = {
      cidr = "10.10.220.0/24"
      az   = "ap-northeast-2c"
    },
  }
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Environment = "prod"
    Owner       = "dolpin"
  }
}

variable "env" {
  description = "환경"
  type        = string
  default     = "prod"
}

### ECR
variable "be_ecr_name" {
  description = "Backend ECR 리포지토리 이름"
  type        = string
  default     = "dolpin-backend"
}

variable "fe_ecr_name" {
  description = "Frontend ECR 리포지토리 이름"
  type        = string
  default     = "dolpin-frontend"
}

variable "image_tag_mutability" {
  description = "태그 변경 가능 여부"
  type        = string
  default     = "IMMUTABLE"
}

variable "scan_on_push" {
  description = "푸시 시 이미지 자동 보안 스캔 여부"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "암호화 방식"
  type        = string
  default     = "AES256"
}

variable "domain_zone_name" {
  description = "환경"
  type        = string
  default     = "dolpin.site"
}

variable "domain_name" {
  description = "환경"
  type        = string
  default     = "dolpin.site"
}

variable "domain_wildcard" {
  description = "도메인 인증서 와일드 카드"
  type        = string
  default     = "*.dolpin.site"
}

variable "fe_alias_name" {
  description = "FE 도메인의 Route53 ALIAS 레코드 이름"
  type        = string
  default     = "dolpin.site"
}

variable "be_alias_name" {
  description = "BE 도메인의 Route53 ALIAS 레코드 이름"
  type        = string
  default     = "be.dolpin.site"
}

variable "db_engine" {
  description = "database engine 종류 (ex: mysql, postgres 등)"
  type = string
  default = "postgres"
}

variable "db_engine_version" {
  description = "database engine 버전"
  type = string
  default = "15.7"
}

variable "db_instance_class" {
  description = "database instance class (ex: db.t3.micro)"
  type = string
  default = "db.t3.micro"
}

variable "db_multi_az" {
  description = "db가 multi az 지원 여부"
  type = bool
  default = true
}

# FE
variable "fe_port" {
  description = "FE 애플리케이션 포트"
  type        = number
  default     = 3000
}

variable "fe_ami_id" {
  description = "FE 인스턴스에 사용할 AMI ID"
  type        = string
  default     = "ami-08943a151bd468f4e"
}

variable "fe_instance_type" {
  description = "FE 인스턴스 타입"
  type        = string
  default     = "t3.small"
}

variable "fe_listener_rule_priority" {
  description = "FE ALB Listener Rule 우선순위"
  type        = number
  default     = 90
}

variable "fe_host_header_values" {
  description = "FE ALB Listener Rule 조건에 사용할 host_header 값 리스트"
  type        = list(string)
  default     = ["dolpin.site"]
}

variable "fe_request_per_target_threshold" {
  description = "FE 오토스케일링: Target 당 요청 수 임계값"
  type        = number
  default     = 60
}

variable "fe_health_check_path" {
  description = "FE ALB 헬스 체크 경로"
  type        = string
  default     = "/api/health"
}

variable "fe_allowed_cidrs" {
  description = "FE 인스턴스로의 접근을 허용할 CIDR 리스트"
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

# BE
variable "be_port" {
  description = "BE 애플리케이션 포트"
  type        = number
  default     = 8080
}

variable "be_ami_id" {
  description = "BE 인스턴스에 사용할 AMI ID"
  type        = string
  default     = "ami-08943a151bd468f4e"
}

variable "be_instance_type" {
  description = "BE 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

variable "be_listener_rule_priority" {
  description = "BE ALB Listener Rule 우선순위"
  type        = number
  default     = 100
}

variable "be_host_header_values" {
  description = "BE ALB Listener Rule 조건에 사용할 host_header 값 리스트"
  type        = list(string)
  default     = ["be.dolpin.site"]
}

variable "be_target_cpu_utilization" {
  description = "BE 오토스케일링: 목표 CPU 사용률"
  type        = number
  default     = 70
}

variable "be_health_check_path" {
  description = "BE ALB 헬스 체크 경로"
  type        = string
  default     = "/api/v1/health"
}

variable "be_allowed_cidrs" {
  description = "BE 인스턴스로의 접근을 허용할 CIDR 리스트"
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

variable "nat_azs" {
  description = "NAT Gateway를 배치할 AZ 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}
