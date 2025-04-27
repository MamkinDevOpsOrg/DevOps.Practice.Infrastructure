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

resource "aws_iam_role" "lambda_restart_role" {
  name = "lambda-ecr-image-watcher"

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

resource "aws_iam_role_policy" "lambda_restart_policy" {
  role = aws_iam_role.lambda_restart_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "lambda_ecr_listener_zip" {
  type        = "zip"
  source_dir  = "${path.module}/modules/lambda_ecr_listener"
  output_path = "${path.module}/builds/lambda_ecr_listener.zip"
}

resource "aws_lambda_function" "ecr_listener" {
  function_name = "ecr_image_listener"

  filename         = data.archive_file.lambda_ecr_listener_zip.output_path
  source_code_hash = data.archive_file.lambda_ecr_listener_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs18.x"
  timeout = 120

  role = aws_iam_role.lambda_restart_role.arn

  environment {
    variables = {
      ECR_REPOSITORY = "ecr-kapset"
    }
  }
}

# ----------------------------------------------------------------------------
# Lambda Function: Analytics Event Handler
# ----------------------------------------------------------------------------
resource "aws_iam_role" "analytics_lambda_role" {
  name = "analytics-lambda-role"

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
resource "aws_iam_role_policy" "analytics_lambda_policy" {
  name = "analytics-lambda-policy"
  role = aws_iam_role.analytics_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "analytics_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_analytics"
  output_path = "${path.module}/builds/analytics_lambda.zip"
}

resource "aws_lambda_function" "analytics_lambda" {
  function_name = "analytics-event-handler"

  filename         = data.archive_file.analytics_lambda_zip.output_path
  source_code_hash = data.archive_file.analytics_lambda_zip.output_base64sha256

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 30
  memory_size = 512

  role = aws_iam_role.analytics_lambda_role.arn

  vpc_config {
    subnet_ids         = module.vpc.private_subnets
    security_group_ids = [aws_security_group.lambda_db_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.analytics_db.address
      DB_NAME     = var.analytics_db_name
      DB_USER     = var.analytics_db_username
      DB_PASSWORD = var.analytics_db_password
    }
  }

  tags = {
    Name = "analytics-lambda"
  }
}
