# ----------------------------------------------------------------------------
# IAM Role and Policy for Analytics Lambdas
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
          "logs:PutLogEvents",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

# ----------------------------------------------------------------------------
# Analytics Event Handler Lambda
# ----------------------------------------------------------------------------
data "archive_file" "analytics_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/modules/lambda_analytics"
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

# ----------------------------------------------------------------------------
# Analytics DB Init Lambda
# ----------------------------------------------------------------------------
data "archive_file" "analytics_db_init_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/modules/lambda_analytics_db_init"
  output_path = "${path.module}/builds/analytics_db_init_lambda.zip"
}

resource "aws_lambda_function" "analytics_db_init_lambda" {
  function_name = "analytics-db-init"

  filename         = data.archive_file.analytics_db_init_lambda_zip.output_path
  source_code_hash = data.archive_file.analytics_db_init_lambda_zip.output_base64sha256

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 60
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
    Name = "analytics-db-init"
  }
}
