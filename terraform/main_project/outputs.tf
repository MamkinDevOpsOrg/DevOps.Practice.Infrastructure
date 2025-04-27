output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.natgw_ids[0]
}

output "analytics_db_endpoint" {
  description = "Endpoint of Analytics PostgreSQL database"
  value       = aws_db_instance.analytics_db.endpoint
}