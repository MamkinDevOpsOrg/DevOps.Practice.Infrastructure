data "archive_file" "lambda_ecr_listener_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/lambda_ecr_listener"
  output_path = "${path.module}/builds/lambda_ecr_listener.zip"
}

resource "aws_lambda_function" "ecr_listener" {
  function_name = "ecr_image_listener-${var.environment}"

  filename         = data.archive_file.lambda_ecr_listener_zip.output_path
  source_code_hash = data.archive_file.lambda_ecr_listener_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 120

  role = aws_iam_role.lambda_restart_role.arn

  environment {
    variables = {
      ECR_REPOSITORY = var.ecr_repository_name
      REGION         = var.region
    }
  }
}

resource "aws_cloudwatch_event_rule" "ecr_latest_image_push" {
  name        = "ecr-latest-image-push-${var.environment}"
  description = "Triggered on push of 'latest' image to ECR"

  event_pattern = jsonencode({
    source        = ["aws.ecr"],
    "detail-type" = ["ECR Image Action"],
    detail = {
      "action-type"     = ["PUSH"],
      "repository-name" = [var.ecr_repository_name],
      "image-tag"       = ["latest"]
    }
  })
}

resource "aws_cloudwatch_event_target" "trigger_lambda_on_image_push" {
  rule      = aws_cloudwatch_event_rule.ecr_latest_image_push.name
  target_id = "ECRImagePushTarget"
  arn       = aws_lambda_function.ecr_listener.arn
}

resource "aws_lambda_permission" "eventbridge_invoke_lambda" {
  statement_id  = "AllowExecutionFromEventBridge_ECRPush"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ecr_listener.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ecr_latest_image_push.arn
}
