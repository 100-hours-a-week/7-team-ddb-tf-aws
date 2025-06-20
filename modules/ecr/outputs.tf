output "repository_url" {
  description = "ECR 리포지토리 URL"
  value       = aws_ecr_repository.this.repository_url
}

output "arn" {
  description = "ECR 리포지토리 ARN"
  value       = aws_ecr_repository.this.arn
}