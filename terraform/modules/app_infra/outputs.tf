output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.dns_name
}
