data "aws_iam_policy_document" "assume_ec2" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid     = "AllowOnlySpecificRole"
    effect  = "Allow"
    actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject","s3:ListObject"]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}