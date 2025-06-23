resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = file("${path.module}/policy/ssm_instance_assume_role.json")
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.role_name}-s3-access"
  path        = "/"
  description = "Access to S3 for Thanos/Loki"
  policy      = file("${path.module}/policy/s3_access_policy.json")
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.this.name
}
