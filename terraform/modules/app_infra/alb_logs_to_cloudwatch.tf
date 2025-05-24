resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/alb/access-logs/${var.environment}"
  retention_in_days = 30
}

data "archive_file" "forward_logs_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda_forward_logs"
  output_path = "${path.module}/builds/forward_logs_lambda.zip"
}

resource "aws_lambda_function" "forward_logs" {
  function_name = "forward-alb-logs"

  filename         = data.archive_file.forward_logs_zip.output_path
  source_code_hash = data.archive_file.forward_logs_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 60

  role = aws_iam_role.forward_logs_role.arn

  environment {
    variables = {
      LOG_GROUP_NAME = aws_cloudwatch_log_group.alb_logs.name
    }
  }
}

resource "aws_lambda_permission" "allow_s3_trigger" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.forward_logs.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.access_log_bucket}"
}

resource "aws_s3_bucket_notification" "alb_logs_to_lambda" {
  bucket = var.access_log_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.forward_logs.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "${var.access_log_prefix}/"
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}
