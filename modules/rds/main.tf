# Database 보안 그룹
resource "aws_security_group" "database" {
  name        = "db-sg-${var.env}"
  description = "Security group for database"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    cidr_blocks = var.allow_cidr_block_list
    security_groups = var.allow_sg_list
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "db-sg-${var.env}"
  })
}

# DB Subnet Group
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-sng-${var.env}"
  subnet_ids = var.db_subnet_ids

  tags = merge(var.common_tags, {
    Name = "db-sng-${var.env}"
  })
}

# db 인스턴스 생성
resource "aws_db_instance" "this" {
  identifier                  = "db-${var.env}"
  engine                      = var.db_engine
  engine_version              = var.db_engine_version
  instance_class              = var.db_instance_class
  allocated_storage           = 20
  username                    = "dolpinuser"
  db_name                     = "dolpin"
  manage_master_user_password = true
  publicly_accessible         = false
  multi_az                    = var.db_multi_az
  vpc_security_group_ids      = [aws_security_group.database.id]
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  tags = merge(var.common_tags, {
    Name = "db-${var.env}"
  })
}

resource "aws_secretsmanager_secret" "backend_db_credentials" {
  name        = "bnd-db-credentials-${var.env}"
  tags        = var.common_tags
}

data "aws_secretsmanager_secret_version" "rds_auto_secret_version" {
  secret_id = aws_db_instance.this.master_user_secret[0].secret_arn
}

resource "aws_secretsmanager_secret_version" "backend_db_secret_value" {
  secret_id = aws_secretsmanager_secret.backend_db_credentials.id

  secret_string = jsonencode({
    host     = aws_db_instance.this.endpoint
    port     = 5432
    username = "dolpinuser"
    password = jsondecode(data.aws_secretsmanager_secret_version.rds_auto_secret_version.secret_string).password
  })
}
