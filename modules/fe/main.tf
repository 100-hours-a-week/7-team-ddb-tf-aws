# FE EC2가 이 Role을 사용할 수 있도록 허용하는 Assume Role 정책 정의
resource "aws_iam_role" "fe_ssm" {
  name               = "fe-ssm-role-${var.env}"
  assume_role_policy = file("${path.module}/policy/assume-role-policy.json")
}

# Session Manager 사용을 위한 필수 권한 부여
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.fe_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 인스턴스에 Instance Profile을 통해 Role을 부여함
resource "aws_iam_instance_profile" "fe" {
  name = "fe-instance-profile-${var.env}"
  role = aws_iam_role.fe_ssm.name
}