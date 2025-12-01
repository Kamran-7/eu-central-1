################### vpc ########################
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "vpc_cidr" {
  value       = module.vpc.vpc_cidr
  description = "VPC CIDR block"
}

output "public_subnet_ids" {
  value       = module.vpc.public_subnet_ids
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = module.vpc.private_subnet_ids
  description = "Private subnet IDs"
}

output "nat_gateway_ip" {
  value       = module.vpc.nat_gateway_public_ip
  description = "NAT Gateway public IP"
}

################### ALB ########################
output "alb_dns_name" {
  value       = module.alb.alb_dns_name
  description = "ALB DNS name"
}

output "alb_arn" {
  value       = module.alb.alb_arn
  description = "ALB ARN"
}

output "alb_zone_id" {
  value       = module.alb.alb_zone_id
  description = "ALB Route53 zone ID"
}

output "target_group_arn" {
  value       = module.alb.target_group_arn
  description = "Target group ARN"
}

output "target_group_name" {
  value       = module.alb.target_group_name
  description = "Target group name"
}

output "alb_security_group_id" {
  value       = module.alb.alb_security_group_id
  description = "ALB security group ID"
}

################### ECR ########################
output "ecr_repository_urls" {
  description = "Map: backend|beat|worker => ECR URL"
  value       = { for k, m in module.ecr : k => m.repository_url }
}

output "ecr_repository_names" {
  description = "Map: backend|beat|worker => ECR name"
  value       = { for k, m in module.ecr : k => m.repository_name }
}

################### ECS ########################
output "ecs_cluster_name" {
  value       = module.ecs.cluster_name
  description = "ECS cluster name"
}

output "ecs_service_arns" {
  value       = module.ecs.service_arns
  description = "ECS service ARNs"
}

