data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ci_policy_doc" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::backup-dolpin-aws",
      "arn:aws:s3:::backup-dolpin-aws/*",
      "arn:aws:s3:::dev-dolpin-codedeploy-artifacts",
      "arn:aws:s3:::dev-dolpin-codedeploy-artifacts/*"
    ]
  }

  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetDeployment",
      "codedeploy:RegisterApplicationRevision"
    ]
    resources = ["*"]
  }

  statement {
    actions = ["iam:PassRole"]
    resources = [
      "arn:aws:iam::794038223418:role/frontend-dev-codedeploy-role",
      "arn:aws:iam::794038223418:role/frontend-prod-codedeploy-role",
      "arn:aws:iam::794038223418:role/backend-dev-codedeploy-role",
      "arn:aws:iam::794038223418:role/backend-prod-codedeploy-role"
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::dolpin-terraform-state-bn2gz7v3he1rj0ia",
      "arn:aws:s3:::dolpin-terraform-state-bn2gz7v3he1rj0ia/*"
    ]
  }
}
