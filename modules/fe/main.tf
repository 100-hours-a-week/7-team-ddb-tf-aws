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

resource "aws_security_group" "fe_sg" {
  name        = "fe-sg-${var.env}"
  description = "Allow FE access"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "fe-sg-${var.env}"
  })
}

# ALB 보안 그룹에서 들어오는 요청만 허용
resource "aws_security_group_rule" "fe_from_alb" {
  type                     = "ingress"
  from_port                = var.fe_port
  to_port                  = var.fe_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.fe_sg.id
  source_security_group_id = var.alb_security_group_id
  description              = "Allow from ALB"
}

# 추가 CIDR → FE 허용
resource "aws_security_group_rule" "fe_from_additional_cidrs" {
  for_each = toset(var.allowed_cidrs)

  type              = "ingress"
  from_port         = var.fe_port
  to_port           = var.fe_port
  protocol          = "tcp"
  cidr_blocks       = [each.key]
  security_group_id = aws_security_group.fe_sg.id
  description       = "Allow from additional CIDR ${each.key}"
}

# EC2 인스턴스 생성하는 템플릿
resource "aws_launch_template" "fe" {
  name_prefix   = "fe-lt-${var.env}"
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.fe.name
  }

  user_data = base64encode(data.template_file.startup.rendered)

  vpc_security_group_ids = [aws_security_group.fe_sg.id]

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name        = "fe-instance-${var.env}"
      environment = var.env
      component   = "fe"
      managedBy   = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = "fe-volume-${var.env}"
      environment = var.env
      component   = "fe"
    }
  }
}

resource "aws_autoscaling_group" "fe" {
  name                      = "fe-asg-${var.env}"
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  vpc_zone_identifier       = var.subnet_ids

  target_group_arns = [aws_lb_target_group.fe.arn]
  health_check_type         = "ELB" 
  health_check_grace_period = 100
  default_instance_warmup = 60

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.fe.id
    version = "Latest"
  }
}

resource "aws_autoscaling_policy" "fe_request_scaling" {
  name                   = "fe-request-scaling-${var.env}"
  autoscaling_group_name = aws_autoscaling_group.fe.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${aws_lb_target_group.fe.arn_suffix}"
    }
    target_value              = var.request_per_target_threshold
    disable_scale_in = false
  }

  depends_on = [aws_lb_target_group.fe]
}

resource "aws_lb_target_group" "fe" {
  name     = "tg-fe-${var.env}"
  port     = var.fe_port
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
    Name = "fe-tg-${var.env}"
  })
}

resource "aws_lb_listener_rule" "fe_host_rule" {
  listener_arn = var.alb_listener_arn_https
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fe.arn
  }

  condition {
    host_header {
      values = var.host_header_values
    }
  }

  depends_on = [aws_lb_target_group.fe]
}