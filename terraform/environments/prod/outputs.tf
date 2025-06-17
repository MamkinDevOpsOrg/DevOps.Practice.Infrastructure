output "alb_dns_name" {
  value = module.app.alb_dns_name
}

output "repository_url" {
  value = module.app.repository_url
}

output "nat_gateway_id" {
  value = module.app.nat_gateway_id
}

output "analytics_db_endpoint" {
  value = module.app.analytics_db_endpoint
}

output "analytics_api_url" {
  value = module.app.analytics_api_url
}

output "analytics_stats_api_url" {
  value = module.app.analytics_stats_api_url
}

output "analytics_db_init_api_url" {
  value = module.app.analytics_db_init_api_url
}

output "sqs_analytics_queue_url" {
  value = module.app.sqs_analytics_queue_url
}

output "sqs_analytics_queue_arn" {
  value = module.app.sqs_analytics_queue_arn
}