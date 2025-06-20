
# VPC
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.common_tags, {
    Name = "vpc-${var.env}"
  })
}

# Public Subnet의 IGW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.common_tags, {
    Name = "igw-${var.env}"
  })
}

# Public Subnet
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.map_public_ip_on_launch

  tags = merge(var.common_tags, {
    Name = "public-${each.key}-${var.env}"
  })
}

# Private Subnet
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(var.common_tags, {
    Name = "private-${each.key}-${var.env}"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.common_tags, {
    Name = "public-rt-${var.env}"
  })
}

# Public subnet에 Route Table 연결
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway Elastic IP
resource "aws_eip" "nat_eip" {
  for_each = local.nat_azs
  
  tags = merge(var.common_tags, {
    Name = "nat-eip-${each.key}-${var.env}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each      = local.nat_azs
  allocation_id = aws_eip.nat_eip[each.key].id
  subnet_id     = lookup({ for k, s in aws_subnet.public : s.availability_zone => s.id }, each.key)

  tags = merge(var.common_tags, {
    Name = "nat-${each.key}-${var.env}"
  })
}

# Private Route Table (NAT Gateway 연결)
resource "aws_route_table" "private" {
  for_each = local.nat_azs
  vpc_id   = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[each.key].id
  }

  tags = merge(var.common_tags, {
    Name = "private-rt-${each.key}-${var.env}"
  })
}

# Private subnet에 Route Table 연결
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = length(local.nat_azs_list) == 1 ? aws_route_table.private[local.nat_azs_list[0]].id : aws_route_table.private[each.value.availability_zone].id
}