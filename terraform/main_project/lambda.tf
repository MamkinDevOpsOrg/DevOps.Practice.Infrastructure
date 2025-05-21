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
  source_dir  = "${path.module}/lambdas/lambda_ecr_listener"
  output_path = "${path.module}/builds/lambda_ecr_listener.zip"
}

resource "aws_lambda_function" "ecr_listener" {
  function_name = "ecr_image_listener"

  filename         = data.archive_file.lambda_ecr_listener_zip.output_path
  source_code_hash = data.archive_file.lambda_ecr_listener_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs20.x"
  timeout = 120

  role = aws_iam_role.lambda_restart_role.arn

  environment {
    variables = {
      ECR_REPOSITORY = "ecr-kapset"
    }
  }
}