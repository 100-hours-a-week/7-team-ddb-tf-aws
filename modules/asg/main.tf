# EC2 인스턴스가 SSM을 사용할 수 있도록 허용하는 IAM Role
resource "aws_iam_role" "ssm" {
  name               = local.role_name
  assume_role_policy = file("${path.module}/policy/ssm_instance_assume_role.json")
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = local.instance_profile
  role = aws_iam_role.ssm.name
}

# EC2 인스턴스용 Security Group 
resource "aws_security_group" "this" {
  name        = local.security_group_name
  description = "Allow ${var.component} access"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = local.security_group_name
  })
}

# ALB에서 오는 트래픽만 EC2에 허용
resource "aws_security_group_rule" "from_alb" {
  type                     = "ingress"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.alb_security_group_id
  description              = "Allow from ALB"
}

# 추가 허용 CIDR로부터의 접근 허용
resource "aws_security_group_rule" "from_additional_cidrs" {
  for_each = toset(var.allowed_cidrs)

  type              = "ingress"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  cidr_blocks       = [each.key]
  security_group_id = aws_security_group.this.id
  description       = "Allow from additional CIDR ${each.key}"
}

resource "aws_launch_template" "this" {
  name_prefix   = local.launch_template
  image_id      = var.ami_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/startup.sh", {}))

  vpc_security_group_ids = [aws_security_group.this.id]

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
      Name        = local.instance_name
      environment = var.env
      component   = var.component
      managedBy   = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name        = local.volume_name
      environment = var.env
      component   = var.component
    }
  }
}

resource "aws_lb_target_group" "this" {
  name     = local.target_group_name
  port     = var.port
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
    Name = local.target_group_name
  })
}

resource "aws_lb_listener_rule" "host_rule" {
  listener_arn = var.alb_listener_arn_https
  priority     = var.listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    host_header {
      values = var.host_header_values
    }
  }

  depends_on = [aws_lb_target_group.this]
}

# Auto Scaling Group 정의 (Launch Template 기반)
resource "aws_autoscaling_group" "this" {
  name                      = local.asg_name
  desired_capacity          = 1
  min_size                  = 1
  max_size                  = 2
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = [aws_lb_target_group.this.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 100
  default_instance_warmup   = 60

  lifecycle {
    create_before_destroy = true
  }

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }
}

# CPU 기반 오토스케일링 정책 (조건부 생성)
resource "aws_autoscaling_policy" "cpu_scaling" {
  count = var.target_cpu_utilization != null ? 1 : 0

  name                   = "${local.scaling_policy_name}-cpu"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value       = var.target_cpu_utilization
    disable_scale_in   = false
  }

  depends_on = [aws_lb_target_group.this, aws_lb_listener_rule.host_rule]
}

# ALB 요청 수 기반 오토스케일링 정책 (조건부 생성)
resource "aws_autoscaling_policy" "request_scaling" {
  count = var.request_per_target_threshold != null ? 1 : 0

  name                   = "${local.scaling_policy_name}-request"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${aws_lb_target_group.this.arn_suffix}"
    }
    target_value       = var.request_per_target_threshold
    disable_scale_in   = false
  }

  depends_on = [aws_lb_target_group.this, aws_lb_listener_rule.host_rule]
}

