# IAM 정책 (비용 조회, 시크릿 조회)
resource "aws_iam_policy" "lambda_cost_explorer_read_policy" {
  name = "LambdaCostExplorerReadAccess"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:GetDimensionValues"
        ],
        Resource = "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-ce-pol-${var.env}"
  })
}

resource "aws_iam_policy" "lambda_secret_read_policy" {
  name = "LambdaSecretReadAccess"
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

# Lambda용 IAM 역할
resource "aws_iam_role" "lambda_cost_explorer_role" {
  name = "lambda-cost-explorer-role"

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

# Lambda 역할에 정책 연결
resource "aws_iam_role_policy_attachment" "attach_cost_explorer_read_policy" {
  role       = aws_iam_role.lambda_cost_explorer_role.name
  policy_arn = aws_iam_policy.lambda_cost_explorer_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_secret_read_policy" {
  role       = aws_iam_role.lambda_cost_explorer_role.name
  policy_arn = aws_iam_policy.lambda_secret_read_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_cost_usage_report_policy" {
  role       = aws_iam_role.lambda_cost_explorer_role.name
  policy_arn = data.aws_iam_policy.cost_usage_report_automation_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_lambda_basic_execution" {
  role       = aws_iam_role.lambda_cost_explorer_role.name
  policy_arn = data.aws_iam_policy.lambda_basic_execution_role.arn
}

# Lambda 함수 정의
resource "aws_lambda_function" "cost_report_lambda" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "cost-report-lambda"
  role             = aws_iam_role.lambda_cost_explorer_role.arn
  source_code_hash = data.archive_file.lambda.output_base64sha256

  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"
  timeout = "60"
  tags = merge(var.common_tags, {
    Name = "${var.component}-lbd-${var.env}"
  })
}

# 스케줄러용 IAM 역할
resource "aws_iam_role" "scheduler_invoke_lambda_role" {
  name = "scheduler-invoke-lambda-role"

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
      Resource = aws_lambda_function.cost_report_lambda.arn
    }]
  })
}

# 스케줄러 설정 
resource "aws_scheduler_schedule" "cost_report_scheduler" {
  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression_cron
  schedule_expression_timezone = "Asia/Seoul"

  target {
    arn      = aws_lambda_function.cost_report_lambda.arn
    role_arn = aws_iam_role.scheduler_invoke_lambda_role.arn
  }
}
