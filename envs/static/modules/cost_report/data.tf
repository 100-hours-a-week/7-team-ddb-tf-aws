data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "lambda_function_payload.zip"
}