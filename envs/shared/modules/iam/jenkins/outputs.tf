output "instance_profile_name" {
  description = "EC2에 연결할 IAM Instance Profile 이름"
  value       = aws_iam_instance_profile.this.name
}