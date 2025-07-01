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

resource "aws_elasticache_replication_group" "this" { 
  replication_group_id       = "${var.redis_prefix}-${var.env}"
  description                = "refresh token 저장할 Redis"
  engine                     = "redis"
  engine_version             = var.redis_engine_version
  node_type                  = var.node_type 
  num_cache_clusters         = var.cache_clusters
  port                       = 6379
  parameter_group_name       = var.parameter_group_name
  subnet_group_name          = aws_elasticache_subnet_group.this.name
  security_group_ids         = [aws_security_group.this.id]
  user_group_ids             = [aws_elasticache_user_group.this.user_group_id]
  transit_encryption_enabled = true
  apply_immediately          = true
  auto_minor_version_upgrade = true
  snapshot_retention_limit   = var.snapshot_retention_limit
  snapshot_window            = "17:00-18:00"

  tags = merge(var.common_tags, {
    Name = "redis-rg-${var.env}"
  })
}

resource "aws_secretsmanager_secret" "redis_credentials" {
  name = "${var.env}/redis/credentials/secret"
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "redis_secret_value" {
  secret_id = aws_secretsmanager_secret.redis_credentials.id

  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.this.primary_endpoint_address
    port     = 6379
    username = aws_elasticache_user.admin.user_name
    password = random_password.redis_password.result
  })
}