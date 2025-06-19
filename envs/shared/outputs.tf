output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = var.vpc_cidr
}

output "private_route_table_ids" {
  value = values(aws_route_table.private)[*].id
}