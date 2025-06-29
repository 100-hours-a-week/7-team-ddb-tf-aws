# EC2 인스턴스용 IAM Role 생성
resource "aws_iam_role" "ec2_instance_role" {
  name               = local.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "default" {
  for_each   = toset(local.default_policy_arns)
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = each.key
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = each.value
}

# SecretsManager 접근 정책 정의 및 Attach
resource "aws_iam_policy" "secrets_access" {
  name   = "${var.component}-${var.env}-AllowSecretsAccess"
  policy = data.aws_iam_policy_document.secrets_access.json
}

resource "aws_iam_role_policy_attachment" "attach_secrets_access" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "this" {
  name = local.instance_profile
  role = aws_iam_role.ec2_instance_role.name
}
