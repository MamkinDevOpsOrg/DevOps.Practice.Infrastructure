output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.dns_name
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.ecr.repository_url
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.natgw_ids[0]
}

output "analytics_db_endpoint" {
  description = "Endpoint of Analytics PostgreSQL database"
  value       = aws_db_instance.analytics_db.endpoint
}

output "analytics_api_url" {
  description = "URL to send analytics events"
  value       = "https://${aws_api_gateway_rest_api.analytics_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.analytics_api_stage.stage_name}/analytics"
}

output "analytics_db_init_api_url" {
  description = "URL to init analytics schema"
  value       = "https://${aws_api_gateway_rest_api.analytics_api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.analytics_api_stage.stage_name}/init-analytics-db"
}

output "analytics_stats_api_url" {
  description = "URL for GET /analytics-stats endpoint"
  value       = "https://${aws_api_gateway_rest_api.analytics_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}/analytics-stats"
}

output "sqs_analytics_queue_url" {
  description = "SQS Queue URL for analytics events"
  value       = aws_sqs_queue.analytics_events.id
}

output "sqs_analytics_queue_arn" {
  description = "SQS Queue ARN for analytics events"
  value       = aws_sqs_queue.analytics_events.arn
}