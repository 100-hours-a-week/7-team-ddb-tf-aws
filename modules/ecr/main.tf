resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  dynamic "encryption_configuration" {
    for_each = var.encryption_type != null ? [var.encryption_type] : []
    content {
      encryption_type = encryption_configuration.value
      kms_key         = encryption_configuration.value == "KMS" ? var.kms_key : null
    }
  }

  tags = merge(var.common_tags, {
    Name        = var.name
    environment = var.env
    component   = "ecr"
    managedBy   = "terraform"
  })
}

resource "aws_ecr_repository_policy" "this" {
  for_each = var.repository_policy != null && var.repository_policy != "" ? { default = var.repository_policy } : {}
  repository = aws_ecr_repository.this.name
  policy     = each.value
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each   = var.enable_lifecycle_policy ? { default = true } : {}
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      for rule in var.lifecycle_policy_rules : {
        rulePriority = rule.rulePriority
        description  = rule.description
        selection = {
          tagStatus   = rule.tagStatus
          countType   = rule.countType
          countUnit   = rule.countUnit
          countNumber = rule.countNumber
        }
        action = {
          type = rule.action_type
        }
      }
    ]
  })
}