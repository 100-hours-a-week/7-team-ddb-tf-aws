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

resource "aws_codedeploy_app" "this" {
  name             = "${var.name_prefix}-codedeploy-app"
  compute_platform = "Server"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-codedeploy-app"
  })
}

# enable_blue_green = true	: BLUE_GREEN + WITH_TRAFFIC_CONTROL + LB 설정
# enable_blue_green = false	: IN_PLACE + WITHOUT_TRAFFIC_CONTROL
resource "aws_codedeploy_deployment_group" "this" {
  app_name              = aws_codedeploy_app.this.name
  deployment_group_name = "${var.name_prefix}-deployment-group"
  service_role_arn      = aws_iam_role.codedeploy_role.arn
  deployment_config_name = var.deployment_config_name
  autoscaling_groups = [var.autoscaling_group_name]

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.instance_name
    }
  }

  dynamic "load_balancer_info" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      target_group_pair_info {
        target_group {
          name = var.blue_target_group_name
        }
        target_group {
          name = var.green_target_group_name
        }

        prod_traffic_route {
          listener_arns = [var.alb_listener_arn]
        }
      }
    }
  }

  dynamic "deployment_style" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      deployment_option = "WITH_TRAFFIC_CONTROL"
      deployment_type   = "BLUE_GREEN"
    }
  }

 dynamic "blue_green_deployment_config" {
    for_each = var.enable_blue_green ? [1] : []
    content {
      deployment_ready_option {
        action_on_timeout = "CONTINUE_DEPLOYMENT"
      }

      green_fleet_provisioning_option {
        action = "COPY_AUTO_SCALING_GROUP"
      }

      terminate_blue_instances_on_deployment_success {
        action                           = "TERMINATE"
        termination_wait_time_in_minutes = 5
      }
    }
  }

  dynamic "deployment_style" {
    for_each = var.enable_blue_green ? [] : [1]
    content {
      deployment_option = "WITHOUT_TRAFFIC_CONTROL"
      deployment_type   = "IN_PLACE"
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_REQUEST"]
  }

  lifecycle {
    ignore_changes = [blue_green_deployment_config[0].green_fleet_provisioning_option]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-codedeploy-dg"
  })
}
