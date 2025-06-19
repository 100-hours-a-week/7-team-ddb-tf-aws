output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "public subnet ID 리스트"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "private subnet ID 리스트"
  value       = [for s in aws_subnet.private : s.id]
}

output "db_subnet_ids" {
  description = "DB subnet ID 리스트"
  value       = [for k, s in aws_subnet.private : s.id if startswith(k, "db")]
}

output "private_route_table_ids" {
  value = values(aws_route_table.private)[*].id
}