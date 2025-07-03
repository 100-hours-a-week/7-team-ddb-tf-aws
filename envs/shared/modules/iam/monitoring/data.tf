data "aws_iam_policy_document" "s3_bucket_policy" {
  for_each = var.s3_buckets
  statement {
    sid    = "AllowOnlyEC2Role"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [ aws_iam_role.this.arn ]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = ["${each.value}/*"]
  }
}