output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "VPC CIDR 블록"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "public subnet ID 리스트"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "이름 기반 private subnet ID"
  value = {
    for name, subnet in aws_subnet.private : name => subnet.id
  }
}

output "db_subnet_ids" {
  description = "DB subnet ID 리스트"
  value       = [for k, s in aws_subnet.private : s.id if startswith(k, "db")]
}

output "private_route_table_ids" {
  description = "AZ별 private route table ID"
  value = {
    for az, rt in aws_route_table.private : az => rt.id
  }
}