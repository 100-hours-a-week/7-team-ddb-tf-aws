resource "aws_elasticache_subnet_group" "this" { 
  name        = "redis-subnet-group-${var.env}"
  subnet_ids  = var.redis_subnet_ids

  tags = merge(var.common_tags, {
    Name = "redis-subnet-group-${var.env}"
  })
}

resource "aws_security_group" "this" {
  name        = "redis-sg-${var.env}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    cidr_blocks     = var.allowed_cidrs
    security_groups = var.allow_sg_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "redis-sg-${var.env}"
  })
}
