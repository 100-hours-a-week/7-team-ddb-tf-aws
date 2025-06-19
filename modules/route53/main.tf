data "aws_route53_zone" "public" {
  name = var.domain_zone_name
}

resource "aws_route53_record" "alias_record" {
  for_each = var.domains_alias
  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.domain_name
  type    = "A"

  alias {
    name                   = each.value.alias_name
    zone_id                = each.value.alias_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "alias_be_record" {
  for_each = var.domains_records
  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.domain_name
  type    = "A"
  records = each.value.records
}