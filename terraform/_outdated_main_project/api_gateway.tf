# ----------------------------------------------------------------------------
# API Gateway Resource: /analytics
# ----------------------------------------------------------------------------
# Create REST API
resource "aws_api_gateway_rest_api" "analytics_api" {
  name        = "analytics-api"
  description = "API Gateway for Analytics Lambda"
}

# Create /analytics resource
resource "aws_api_gateway_resource" "analytics_resource" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  parent_id   = aws_api_gateway_rest_api.analytics_api.root_resource_id
  path_part   = "analytics"
}

# POST method
resource "aws_api_gateway_method" "analytics_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.analytics_api.id
  resource_id   = aws_api_gateway_resource.analytics_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda Integration
resource "aws_api_gateway_integration" "analytics_integration" {
  rest_api_id             = aws_api_gateway_rest_api.analytics_api.id
  resource_id             = aws_api_gateway_resource.analytics_resource.id
  http_method             = aws_api_gateway_method.analytics_post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.analytics_lambda.invoke_arn
}

# Deployment
resource "aws_api_gateway_deployment" "analytics_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.analytics_integration,
    aws_api_gateway_integration.analytics_get_integration,
    aws_api_gateway_integration.init_analytics_db_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id

  description = "Deployment for analytics API"
}

# Stage "dev"
resource "aws_api_gateway_stage" "analytics_api_stage" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.analytics_api.id
  deployment_id = aws_api_gateway_deployment.analytics_api_deployment.id
  description   = "Dev stage for analytics API"
}

# Grant permission to API Gateway to call Lambda
resource "aws_lambda_permission" "allow_api_gateway_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.analytics_api.execution_arn}/*/*"
}

# ----------------------------------------------------------------------------
# API Gateway GET method on /analytics
# ----------------------------------------------------------------------------
resource "aws_api_gateway_method" "analytics_get_method" {
  rest_api_id   = aws_api_gateway_rest_api.analytics_api.id
  resource_id   = aws_api_gateway_resource.analytics_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "analytics_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  resource_id = aws_api_gateway_resource.analytics_resource.id
  http_method = aws_api_gateway_method.analytics_get_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.analytics_data_getter_lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_analytics_get" {
  statement_id  = "AllowExecutionFromAPIGatewayAnalyticsGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_data_getter_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.analytics_api.execution_arn}/*/*"
}

# ----------------------------------------------------------------------------
# API Gateway Resource: /init-analytics-db
# ----------------------------------------------------------------------------
resource "aws_api_gateway_resource" "init_analytics_db_resource" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  parent_id   = aws_api_gateway_rest_api.analytics_api.root_resource_id
  path_part   = "init-analytics-db"
}

resource "aws_api_gateway_method" "init_analytics_db_post_method" {
  rest_api_id   = aws_api_gateway_rest_api.analytics_api.id
  resource_id   = aws_api_gateway_resource.init_analytics_db_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "init_analytics_db_integration" {
  rest_api_id = aws_api_gateway_rest_api.analytics_api.id
  resource_id = aws_api_gateway_resource.init_analytics_db_resource.id
  http_method = aws_api_gateway_method.init_analytics_db_post_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.analytics_db_init_lambda.invoke_arn
}

resource "aws_lambda_permission" "allow_api_gateway_invoke_init_analytics_db" {
  statement_id  = "AllowExecutionFromAPIGatewayInitAnalyticsDb"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_db_init_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.analytics_api.execution_arn}/*/*"
}
