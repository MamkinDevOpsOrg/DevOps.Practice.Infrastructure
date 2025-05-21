output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.alb.dns_name
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.ecr.repository_url
}
