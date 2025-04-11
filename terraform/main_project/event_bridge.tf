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


