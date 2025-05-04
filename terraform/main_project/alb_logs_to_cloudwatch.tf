# This file configures full automation to forward ALB access logs from S3 to CloudWatch Logs.
#
# ▸ Purpose: Enable real-time processing and querying of ALB logs using CloudWatch Logs Insights.
# ▸ Solves: Makes ALB logs accessible in structured format beyond plain S3 storage.
#
# Resources:
#   - IAM Role & Policy for Lambda to access S3 + CloudWatch Logs
#   - CloudWatch Log Group to store structured logs
#   - Lambda function deployment from zip
#   - S3 event notification to trigger Lambda on new log files
#   - Lambda permission for S3 to invoke the function

resource "aws_iam_role" "forward_logs_role" {
  name = "alb-logs-forward-role"

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

resource "aws_iam_role_policy" "forward_logs_policy" {
  role = aws_iam_role.forward_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject"],
        Resource = "arn:aws:s3:::alb-access-logs-storage-for-mamkindevops-dev-1/*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "alb_logs" {
  name              = "/alb/access-logs"
  retention_in_days = 30
}

data "archive_file" "forward_logs_zip" {
  type        = "zip"
  source_dir  = "${path.module}/modules/lambda_forward_logs"
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
  source_arn    = "arn:aws:s3:::alb-access-logs-storage-for-mamkindevops-dev-1"
}

resource "aws_s3_bucket_notification" "alb_logs_to_lambda" {
  bucket = "alb-access-logs-storage-for-mamkindevops-dev-1"

  lambda_function {
    lambda_function_arn = aws_lambda_function.forward_logs.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "app1/"
  }

  depends_on = [aws_lambda_permission.allow_s3_trigger]
}
