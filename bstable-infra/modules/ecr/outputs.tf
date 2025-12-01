output "repository_url" {
  description = "ECR repository URL"
  value       = local.repo_url
}

output "repository_name" {
  description = "ECR repository name"
  value       = local.repo_name
}

output "repository_arn" {
  description = "ECR repository ARN"
  value       = local.repo_arn
}
