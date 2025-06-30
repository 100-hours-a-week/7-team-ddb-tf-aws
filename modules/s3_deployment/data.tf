data "aws_iam_policy_document" "codedeploy_s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}
