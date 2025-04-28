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
resource "aws_lambda_function" "analytics_lambda" {
  function_name = "analytics-event-handler"

  s3_bucket = var.s3_instance_name
  s3_key    = "lambda/placeholders/placeholder.zip"

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 30
  memory_size = 512
  publish     = false

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
    Name = "analytics-event-handler"
  }
}

# ----------------------------------------------------------------------------
# Analytics DB Init Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_db_init_lambda" {
  function_name = "analytics-db-init"

  s3_bucket = var.s3_instance_name
  s3_key    = "lambda/placeholders/placeholder.zip"

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 60
  memory_size = 512
  publish     = false

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

# ----------------------------------------------------------------------------
# Analytics Data Getter Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_data_getter_lambda" {
  function_name = "analytics-data-getter"

  s3_bucket = var.s3_instance_name
  s3_key    = "lambda/placeholders/placeholder.zip"

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 30
  memory_size = 512
  publish     = false

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
    Name = "analytics-data-getter"
  }
}