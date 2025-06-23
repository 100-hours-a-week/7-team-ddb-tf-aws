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

# Security Group for BE
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
  description              = "Allow from ALB"
}

# shared CIDR → BE 허용
resource "aws_security_group_rule" "be_from_additional_cidrs" {
  for_each = toset(var.allowed_cidrs)

  type              = "ingress"
  from_port         = var.be_port
  to_port           = var.be_port
  protocol          = "tcp"
  cidr_blocks       = [each.key]
  security_group_id = aws_security_group.be_sg.id
  description       = "Allow from additional CIDR ${each.key}"
}

# EC2 인스턴스 생성하는 템플릿
resource "aws_launch_template" "be" {
  name_prefix   = "be-lt-${var.env}"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.be.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/startup.sh", {}))

  vpc_security_group_ids = [aws_security_group.be_sg.id]

  monitoring {
    enabled = true
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      delete_on_termination = true
      encrypted             = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "be-instance-${var.env}"
      environment = var.env
      component   = "be"
      managedBy   = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "be-volume-${var.env}"
      environment = var.env
      component   = "be"
    }
  }
}

resource "aws_autoscaling_group" "be" {
  name                      = "be-asg-${var.env}"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  vpc_zone_identifier       = var.subnet_ids

  target_group_arns         = [aws_lb_target_group.be.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 100
  default_instance_warmup = 60

  force_delete               = false

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.be.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "be_cpu_scaling" {
  name                   = "be-cpu-scaling-${var.env}"
  autoscaling_group_name = aws_autoscaling_group.be.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.target_cpu_utilization
    disable_scale_in = false
  }

  depends_on = [aws_lb_target_group.be, aws_lb_listener_rule.be_host_rule]
}

resource "aws_lb_target_group" "be" {
  name     = "tg-be-${var.env}"
  port     = var.be_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = var.health_check_path
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  target_type = "instance"

  tags = merge(var.common_tags, {
    Name = "be-tg-${var.env}"
  })
}

resource "aws_lb_listener_rule" "be_host_rule" {
  listener_arn = var.alb_listener_arn_https
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.be.arn
  }

  condition {
    host_header {
      values = var.host_header_values
    }
  }

  depends_on = [aws_lb_target_group.be]
}