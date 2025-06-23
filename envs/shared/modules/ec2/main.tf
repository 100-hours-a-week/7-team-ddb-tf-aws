resource "aws_iam_role" "this" {
  name               = "${var.name}-ssm-role"
  assume_role_policy = file("${path.module}/policy/ssm_instance_assume_role.json")
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.this.name
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-${var.name}-sg"
  description = "Security Group for ${var.name}"
  vpc_id      = var.vpc_id

  # CIDR 기반 ingress
  dynamic "ingress" {
    for_each = flatten([
      for rule in var.ingress_rules : [
        for cidr in rule.cidrs : {
          port = rule.port
          cidr = cidr
        }
      ]
    ])
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = [ingress.value.cidr]
    }
  }

  # 보안 그룹 기반 ingress
  dynamic "ingress" {
    for_each = flatten([
      for rule in var.ingress_rules : [
        for sg_id in rule.source_security_group_ids : {
          port = rule.port
          sg   = sg_id
        }
      ]
    ])
    content {
      from_port                = ingress.value.port
      to_port                  = ingress.value.port
      protocol                 = "tcp"
      security_groups          = [ingress.value.sg]
      description              = "Allow SG access on port ${ingress.value.port}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${var.name}-sg"
  })
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.this.id]
  iam_instance_profile   = aws_iam_instance_profile.this.name
  key_name               = null

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    delete_on_termination = true
    tags = {
      Name = "${var.name}-root-volume"
    }
  }

  tags = merge(var.common_tags, {
    Name = var.name
  })

  user_data = var.user_data
}
