resource "aws_iam_role" "codedeploy_role" {
  name               = "${var.name_prefix}-codedeploy-role"
  assume_role_policy = data.aws_iam_policy_document.codedeploy_assume_role.json
  
  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-codedeploy-role"
  })
}

resource "aws_iam_role_policy_attachment" "attach_codedeploy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
