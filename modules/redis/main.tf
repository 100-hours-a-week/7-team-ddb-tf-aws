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

resource "aws_elasticache_user" "admin" {
  user_id       = "refresh-token-user-${var.env}"
  user_name     = "refresh"
  engine        = "redis"
  access_string = "on ~* +@all"
  passwords     = [random_password.redis_password.result]

  tags = merge(var.common_tags, {
    Name = "redis-user-${var.env}"
  })
}

resource "aws_elasticache_user_group" "this" { 
  engine        = "redis"
  user_group_id = "refresh-token-group-${var.env}"
  user_ids      = [aws_elasticache_user.admin.user_id]

  lifecycle {
    ignore_changes = [user_ids]
  }

  tags = merge(var.common_tags, {
    Name = "redis-user-group-${var.env}"
  })
}

resource "random_password" "redis_password" {
  length  = 32
  special = true
  override_special = "!@#$%^&*()-_+[]{}<>?,."
}
