resource "aws_iam_policy" "lambda_tf_automation_policy" {
  name = "LambdaResouceAtuomation"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:DescribeInstances", 
          "rds:StartDBInstance",
          "rds:StopDBInstance",
          "rds:DescribeDBInstances",
          "rds:ListTagsForResource",
          "autoscaling:DescribeTags",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        "Resource" : "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-resouce-atuo-${var.env}"
  })
}

resource "aws_iam_policy" "lambda_secret_read_policy" {
  name = "${var.component}-LambdaSecretReadAccess-${var.env}"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:ap-northeast-2:794038223418:secret:discord/webhook-3JLYiI"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-sec-pol-${var.env}"
  })
}

resource "aws_iam_role" "lambda_tf_automation_role" {
  name = "lambdaTfAutomationRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-lbd-role-${var.env}"
  })
}

resource "aws_iam_role_policy_attachment" "attach_tf_automation_policy" {
  role       = aws_iam_role.lambda_tf_automation_role.name
  policy_arn = aws_iam_policy.lambda_tf_automation_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secret_read_policy" {
  role       = aws_iam_role.lambda_tf_automation_role.name
  policy_arn = aws_iam_policy.lambda_secret_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_basic_execution" {
  role       = aws_iam_role.lambda_tf_automation_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role.arn
}


# Lambda 함수 정의
resource "aws_lambda_function" "tf_automation_lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "tf-automation-lambda"
  role             = aws_iam_role.lambda_tf_automation_role.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"
  tags = merge(var.common_tags, {
    Name = "${var.component}-lbd-${var.env}"
  })
}

# 스케줄러용 IAM 역할
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-tf-automation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "scheduler.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-sch-role-${var.env}"
  })
}

resource "aws_iam_role_policy" "scheduler_lambda_invoke_policy" {
  role = aws_iam_role.scheduler_invoke_lambda_role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "lambda:InvokeFunction",
      Resource = aws_lambda_function.tf_automation_lambda.arn
    }]
  })
}

# 스케줄러 설정 
resource "aws_scheduler_schedule" "tf_automation_scheduler" {
  for_each = local.lambda_schedules

  name = "tf_${each.key}"
  
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = each.value.schedule_expression
  schedule_expression_timezone = "Asia/Seoul"

  target {
    arn      = aws_lambda_function.tf_automation_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
    input = jsonencode({
      action = each.value.action
      env    = each.value.env
      min_size = each.value.min_size
      desired_size = each.value.desired_size
      max_size = each.value.max_size
    })
  }
}
