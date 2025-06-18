# BE EC2가 이 Role을 사용할 수 있도록 허용하는 Assume Role 정책 정의
resource "aws_iam_role" "be_ssm" {
  name               = "be-ssm-role-${var.env}"
  assume_role_policy = file("${path.module}/policy/assume-role-policy.json")
}

# Session Manager 사용을 위한 필수 권한 부여
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.be_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EC2 인스턴스에 Instance Profile을 통해 Role을 부여함
resource "aws_iam_instance_profile" "be" {
  name = "be-instance-profile-${var.env}"
  role = aws_iam_role.be_ssm.name
}

resource "aws_security_group" "be_sg" {
  name        = "be-sg-${var.env}"
  description = "Allow BE access"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "be-sg-${var.env}"
  })
}

# ALB 보안 그룹에서 들어오는 요청만 허용
resource "aws_security_group_rule" "be_from_alb" {
  type                     = "ingress"
  from_port                = var.be_port
  to_port                  = var.be_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.be_sg.id
  source_security_group_id = var.alb_security_group_id
}