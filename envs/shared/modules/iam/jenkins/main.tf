resource "aws_iam_role" "this" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_apply_attach" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::794038223418:policy/dolpin-terraform"
}

resource "aws_iam_role_policy_attachment" "jenkins_codedeploy_full_access" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
}

resource "aws_iam_policy" "jenkins_ci_policy" {
  name   = "jenkins-ci-policy"
  policy = data.aws_iam_policy_document.ci_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "jenkins_ci_policy_attach" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.jenkins_ci_policy.arn
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.this.name
}
