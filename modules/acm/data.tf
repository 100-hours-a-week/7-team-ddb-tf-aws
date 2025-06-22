data "aws_route53_zone" "public" {
  name = var.domain_zone_name
}