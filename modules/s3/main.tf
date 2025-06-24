# 이미지 파일 저장할 S3 bucket 생성
resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true 

  tags = merge(var.common_tags, {
    Name = var.bucket_name
  })
}

# 외부 주체가 객체를 업로드하더라도 버킷 소유자가 해당 객체의 소유자가 되도록 설정
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerPreferred" 
  }
}

# S3 퍼블릭 접근을 방지
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# CORS 설정
resource "aws_s3_bucket_cors_configuration" "cors" {
  bucket = aws_s3_bucket.this.id

  cors_rule {
    allowed_methods = ["GET", "HEAD", "PUT", "POST"]
    allowed_origins = var.cors_origins
    allowed_headers = ["*"]
    expose_headers  = ["ETag", "x-amz-request-id"]
    max_age_seconds = 3600
  }
}

# 객체 버전 관리 설정
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 객체 저장 시 자동으로 암호화 수행
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
