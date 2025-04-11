module "lambda_trigger_cpu" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "trigger_cpu_load"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  source_path   = "./lambda/trigger_cpu"
  timeout       = 65


  environment_variables = {
    TARGET_URL = "http://${module.alb.dns_name}/v1/load/cpu"
  }

  tags = {
    Name = "trigger_cpu_load"
  }
}

module "lambda_trigger_mem" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "trigger_mem_load"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  source_path   = "./lambda/trigger_mem"
  timeout       = 65

  environment_variables = {
    TARGET_URL = "http://${module.alb.dns_name}/v1/load/mem"
  }

  tags = {
    Name = "trigger_mem_load"
  }
}
