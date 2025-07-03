variable "role_name" {
  description = "EC2에 연결할 IAM Role 이름"
  type        = string
}


variable "s3_buckets" {
  description = "EC2가 접근할 S3 버킷의 이름과 ARN 목록"
  type        = map(string)
}