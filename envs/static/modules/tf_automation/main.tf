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
          "rds:DescribeDBInstances"
        ],
        "Resource" : "*"
      }
    ]
  })
  tags = merge(var.common_tags, {
    Name = "${var.component}-resouce-atuo-${var.env}"
  })
}

resource "aws_iam_role" "lambda_tf_automation_role" {
  name = "lambda-tf-automation-role"

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
  role       = aws_iam_role.lambda_tf_automation_role.arn
  policy_arn = aws_iam_policy.lambda_tf_automation_policy.arn
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