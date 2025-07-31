# 7-team-ddb AWS Terraform

Dolpin 서비스의 AWS 인프라를 Terraform으로 관리하는 코드 저장소입니다.

## 프로젝트 개요

- Dolpin 서비스에 필요한 AWS 인프라 전체를 코드(IaC)로 관리합니다.
- Terraform을 사용하여 인프라 구성, 배포 자동화, 모니터링, 비용 관리까지 수행합니다.

## 빠른 시작

### Terraform 초기화 및 적용

```bash
# 원격 상태(S3 Bucket) 설정
cd backend
terraform init && terraform apply

# 환경별 프로비저닝 (static → shared → (dev/prod) 순서)
cd ../envs/
terraform init && terraform apply

```

### 핵심 인프라 구성

### 

네트워크: VPC, Subnet, Peering, NAT, Site-To-Site VPN

도메인 : Route 53, ACM

컴퓨팅: EC2, Auto Scaling Group, Application Load Balancer

컨테이너 및 배포: Docker, ECR, CodeDeploy, Jenkins

데이터베이스: RDS, ElastiCache Redis

정적 자산 관리: S3 + CloudFront CDN

모니터링: Prometheus, Grafana, Loki, Thanos, S3, Node Exporter, Promtail

비용 최적화 및 알림 : EventBridge Scheduler, Lambda, Cost Explorer, Discord

### 문서(Wiki)

[Cloud 아키텍처 설계 및 운영 가이드](https://github.com/100-hours-a-week/7-team-ddb-wiki/wiki/1.-Cloud-Wiki)

### 디렉토리 구성

```bash
.github/
backend/
envs/
  ├── dev/
  ├── prod/
  ├── shared/
  └── static/
modules/
  ├── acm/
  ├── asg/
  ├── codedeploy/
  ├── ecr/
  ├── loadbalancer/
  ├── network/
  ├── rds/
  ├── redis/
  ├── route53/
  ├── s3_cloudfront/
  ├── s3_deployment/
  └── vpc_peering/
jenkinsfile/
.gitignore
.gitmessage.txt

```
