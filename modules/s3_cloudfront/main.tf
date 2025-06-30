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
  block_public_policy     = false
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

# OAC
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_name}-oac"
  origin_access_control_origin_type = "s3"      
  signing_behavior                  = "always" 
  signing_protocol                  = "sigv4"   
}

# 이미지 파일에 대한 CDN 경로를 생성
resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.this.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  enabled             = true
  is_ipv6_enabled     = true

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.this.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    cache_policy_id            = aws_cloudfront_cache_policy.image_cdn_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cors.id
    compress = true

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn   
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
    cloudfront_default_certificate = false
  }

  aliases = [var.domain_name] 

  tags = merge(var.common_tags, {
    Name = "cdn-${var.bucket_name}"
  })
}

resource "aws_cloudfront_cache_policy" "image_cdn_cache" {
  name = "image-cdn-cache-${var.env}"

  default_ttl = 3600  
  max_ttl     = 86400 
  min_ttl     = 0      

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {  
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin"]
      }
    }

    query_strings_config { 
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "cors" {
  name = "cors-policy-${var.env}"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS", "PUT"]
    }
    access_control_allow_origins {
      items = var.cors_origins
    }
    origin_override = true
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "allow_cf" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_combined.json
}

# S3와 CloudFront 연결 위한 리소스
data "aws_iam_policy_document" "allow_combined" {
  statement {
    sid     = "AllowCloudFrontOAC"
    effect  = "Allow"
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"]
    }
  }

  statement {
    sid     = "AllowPresignedUpload"
    effect  = "Allow"
    actions = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}