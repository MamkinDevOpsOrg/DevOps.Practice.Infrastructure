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
      },
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = aws_sqs_queue.analytics_events.arn
      },

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
      SQS_QUEUE_URL = aws_sqs_queue.analytics_events.id
      DB_HOST       = aws_db_instance.analytics_db.address
      DB_NAME       = var.analytics_db_name
      DB_USER       = var.analytics_db_username
      DB_PASSWORD   = var.analytics_db_password
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

# ----------------------------------------------------------------------------
# Analytics SQS-consumer Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_sqs_consumer_lambda" {
  function_name = "analytics-sqs-consumer"
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 60
  memory_size   = 512
  publish       = false

  role = aws_iam_role.analytics_lambda_role.arn

  s3_bucket = var.s3_instance_name
  s3_key    = "lambda/placeholders/placeholder.zip"

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
    Name = "analytics-sqs-consumer"
  }
}

resource "aws_lambda_event_source_mapping" "analytics_sqs_trigger" {
  event_source_arn = aws_sqs_queue.analytics_events.arn
  function_name    = aws_lambda_function.analytics_sqs_consumer_lambda.arn
  enabled          = true
  batch_size       = 10
  // Lambda receives messages in batches from SQS (up to batchSize).
  // If an error occurs during processing, the ENTIRE batch is retried.
  // To avoid message loss or duplicate processing:
  // - Ensure inserts are idempotent (e.g., use ON CONFLICT in SQL).
  // - Wrap per-message logic in try/catch to prevent one failure from affecting others.
  // - Consider configuring a Dead Letter Queue (DLQ) for permanently failing messages.
}
