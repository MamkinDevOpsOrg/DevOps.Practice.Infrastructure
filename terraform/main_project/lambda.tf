module "lambda_trigger_cpu" {
  source = "terraform-aws-modules/lambda/aws"

  function_name  = "trigger_cpu_load"
  handler        = "index.handler"
  runtime        = "nodejs20.x"
  timeout        = 65
  publish        = false
  create_package = false

  s3_existing_package = {
    bucket = var.s3_instance_name
    key    = "lambda/placeholders/placeholder.zip"
  }


  environment_variables = {
    TARGET_URL = "http://${module.alb.dns_name}/v1/load/cpu"
  }

  tags = {
    Name = "trigger_cpu_load"
  }
}

module "lambda_trigger_mem" {
  source = "terraform-aws-modules/lambda/aws"

  function_name  = "trigger_mem_load"
  handler        = "index.handler"
  runtime        = "nodejs20.x"
  timeout        = 65
  publish        = false
  create_package = false

  s3_existing_package = {
    bucket = var.s3_instance_name
    key    = "lambda/placeholders/placeholder.zip"
  }

  environment_variables = {
    TARGET_URL = "http://${module.alb.dns_name}/v1/load/mem"
  }

  tags = {
    Name = "trigger_mem_load"
  }
}


