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