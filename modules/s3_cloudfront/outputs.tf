output "cloudfront_domain_name" {
  description = "CloudFront 배포 도메인 이름"
  value       = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_zone_id" {
  description = "CloudFront 고정 호스팅존 ID"
  value       = "Z2FDTNDATAQYW2"
}