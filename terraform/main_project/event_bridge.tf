module "eventbridge_lambda_triggers" {
  source = "terraform-aws-modules/eventbridge/aws"

  create_bus = false

  rules = {
    trigger_cpu = {
      description         = "Trigger CPU load Lambda every 10 seconds"
      schedule_expression = "rate(1 minute)"
    }
    trigger_mem = {
      description         = "Trigger Memory load Lambda every 10 seconds"
      schedule_expression = "rate(1 minute)"
    }
  }

  targets = {
    trigger_cpu = [
      {
        name = "cpu-load-target"
        arn  = module.lambda_trigger_cpu.lambda_function_arn
      }
    ]

    trigger_mem = [
      {
        name = "mem-load-target"
        arn  = module.lambda_trigger_mem.lambda_function_arn
      }
    ]
  }

  lambda_target_arns = [
    module.lambda_trigger_cpu.lambda_function_arn,
    module.lambda_trigger_mem.lambda_function_arn
  ]
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_cpu" {
  statement_id  = "AllowExecutionFromEventBridgeCPU"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_trigger_cpu.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_lambda_triggers.eventbridge_rule_arns["trigger_cpu"]
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke_mem" {
  statement_id  = "AllowExecutionFromEventBridgeMEM"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_trigger_mem.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.eventbridge_lambda_triggers.eventbridge_rule_arns["trigger_mem"]
}

# === EventBridge Rule for ECR PUSH latest ===
resource "aws_cloudwatch_event_rule" "ecr_latest_image_push" {
  name        = "ecr-latest-image-push"
  description = "Triggered on push of 'latest' image to ECR"

  event_pattern = jsonencode({
    source        = ["aws.ecr"],
    "detail-type" = ["ECR Image Action"],
    detail = {
      "action-type"     = ["PUSH"],
      "repository-name" = ["ecr-kapset"],
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
