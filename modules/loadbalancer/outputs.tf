output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "alb_sg_id" {
  description = "ALB에 부착된 Security Group ID"
  value       = aws_security_group.this.id
}

output "alb_arn_suffix" {
  description = "ALB의 ARN Suffix"
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}