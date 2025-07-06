data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}

data "aws_iam_policy" "lambda_basic_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}