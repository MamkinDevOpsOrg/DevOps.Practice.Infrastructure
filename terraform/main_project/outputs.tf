output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.dns_name
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = module.vpc.natgw_ids[0]
}