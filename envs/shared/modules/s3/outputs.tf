output "bucket_name" {
  description = "버킷 이름"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "버킷 ARN"
  value       = aws_s3_bucket.this.arn
}
