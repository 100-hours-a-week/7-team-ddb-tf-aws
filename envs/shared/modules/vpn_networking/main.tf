resource "aws_vpn_gateway_route_propagation" "this" {
  for_each = var.private_rt
  vpn_gateway_id = data.aws_vpn_gateway.this.id 
  route_table_id = each.value
}