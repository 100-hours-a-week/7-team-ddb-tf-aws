output "role_arn" {
  description = "생성된 IAM Role ARN"
  value       = aws_iam_role.this.arn
}

output "instance_profile_name" {
  description = "생성된 Instance Profile 이름"
  value       = aws_iam_instance_profile.this.name
}