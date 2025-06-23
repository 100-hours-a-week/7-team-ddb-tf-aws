resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = file("${path.module}/policy/ssm_instance_assume_role.json")
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  count      = var.attach_ecr ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_policy" "s3_access" {
  count       = var.attach_s3 ? 1 : 0
  name        = "${var.role_name}-s3-access"
  path        = "/"
  description = "Access to S3 for Thanos/Loki"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:*"],
      Resource = [
        ////
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "s3" {
  count      = var.attach_s3 ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.s3_access[0].arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.this.name
}
