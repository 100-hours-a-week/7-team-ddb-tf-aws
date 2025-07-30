resource "aws_iam_role" "lambda_role" {
  name = "${var.component}-${var.env}-cdhook-role"

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
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.component}-${var.env}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:ListDeployments",
          "codedeploy:GetDeployment",
          "codedeploy:GetApplicationRevision"
        ],
        Resource = [
          "arn:aws:codedeploy:ap-northeast-2:794038223418:deploymentconfig:CodeDeployDefault.AllAtOnce",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:application:frontend-dev-codedeploy-app",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:application:frontend-prod-codedeploy-app",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:application:backend-dev-codedeploy-app",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:application:backend-prod-codedeploy-app",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:deploymentgroup:frontend-dev-codedeploy-app/frontend-dev-deployment-group",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:deploymentgroup:frontend-prod-codedeploy-app/frontend-prod-deployment-group",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:deploymentgroup:backend-dev-codedeploy-app/backend-dev-deployment-group",
          "arn:aws:codedeploy:ap-northeast-2:794038223418:deploymentgroup:backend-prod-codedeploy-app/backend-prod-deployment-group"
        ]
      },
      {
        Effect = "Allow",
        Action = "autoscaling:CompleteLifecycleAction",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = "ec2:DescribeInstances",
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "codedeploy_trigger" {
  function_name = "${var.component}-${var.env}-codedeploy-hook"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  role    = aws_iam_role.lambda_role.arn
  runtime = "python3.13"
  handler = "lambda_function.lambda_handler"
  timeout = 60

  tags = var.common_tags
}

resource "aws_cloudwatch_event_rule" "asg_event" {
  name = "${var.component}-${var.env}-asg-lifecycle"

  event_pattern = jsonencode({
    "source": ["aws.autoscaling"],
    "detail-type": ["EC2 Instance-launch Lifecycle Action"]
  })
}

resource "aws_cloudwatch_event_target" "asg_lambda_target" {
  rule      = aws_cloudwatch_event_rule.asg_event.name
  target_id = "trigger-lambda"
  arn       = aws_lambda_function.codedeploy_trigger.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.codedeploy_trigger.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_event.arn
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/files"
  output_path = "${path.module}/lambda_function_payload.zip"
}
