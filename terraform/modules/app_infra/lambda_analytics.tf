resource "aws_security_group" "lambda_db_sg" {
  name        = "analytics-lambda-sg-${var.environment}"
  description = "Allow Lambda to access anything needed"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow all outbound traffic (including to RDS, Internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "analytics-lambda-sg-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# Analytics Event Handler Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_lambda" {
  function_name = "analytics-event-handler-${var.environment}"

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
      SQS_QUEUE_URL = aws_sqs_queue.analytics_events.id
      DB_HOST       = aws_db_instance.analytics_db.address
      DB_NAME       = var.analytics_db_name
      DB_USER       = var.analytics_db_username
      DB_PASSWORD   = var.analytics_db_password
    }
  }


  tags = {
    Name        = "analytics-event-handler-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# Analytics DB Init Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_db_init_lambda" {
  function_name = "analytics-db-init-${var.environment}"

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
    Name        = "analytics-db-init-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# Analytics Data Getter Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_data_getter_lambda" {
  function_name = "analytics-data-getter-${var.environment}"

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
    Name        = "analytics-data-getter-${var.environment}"
    Environment = var.environment
  }
}

# ----------------------------------------------------------------------------
# Analytics SQS-consumer Lambda
# ----------------------------------------------------------------------------
resource "aws_lambda_function" "analytics_sqs_consumer_lambda" {
  function_name = "analytics-sqs-consumer-${var.environment}"
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
    Name        = "analytics-sqs-consumer-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "analytics_sqs_trigger" {
  event_source_arn                   = aws_sqs_queue.analytics_events.arn
  function_name                      = aws_lambda_function.analytics_sqs_consumer_lambda.arn
  enabled                            = true
  batch_size                         = 20
  maximum_batching_window_in_seconds = 2
  #  Lambda receives messages in batches from SQS (up to batchSize).
  #  If an error occurs during processing, the ENTIRE batch is retried.
  #  To avoid message loss or duplicate processing:
  #  - Ensure inserts are idempotent (e.g., use ON CONFLICT in SQL).
  #  - Wrap per-message logic in try/catch to prevent one failure from affecting others.
  #  - Consider configuring a Dead Letter Queue (DLQ) for permanently failing messages.

  # Using `batch_size` and `maximum_batching_window_in_seconds` together helps optimize Lambda invocations from SQS. 
  # `batch_size` defines the max number of messages per invocation,
  # while `batching_window` gives Lambda time to collect more messages before triggering.
  # This reduces invocation count, improves processing efficiency, and minimizes DB load by handling more messages per execution.
}
