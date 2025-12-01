output "alb_id" {
  value       = aws_lb.main.id
  description = "ALB ID"
}

output "alb_arn" {
  value       = aws_lb.main.arn
  description = "ALB ARN"
}

output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name"
}

output "alb_zone_id" {
  value       = aws_lb.main.zone_id
  description = "ALB Route53 zone ID"
}

output "target_group_arn" {
  value       = aws_lb_target_group.backend.arn
  description = "Target group ARN"
}

output "target_group_name" {
  value       = aws_lb_target_group.backend.name
  description = "Target group name"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "ALB security group ID"
}

output "listener_arn" {
  value       = aws_lb_listener.http.arn
  description = "HTTP listener ARN"
}

output "alb_arn_suffix" {
  value = aws_lb.main.arn_suffix
}
output "target_group_arn_suffix" {
  value = aws_lb_target_group.backend.arn_suffix
}

