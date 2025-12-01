output "cluster_id" {
  value       = aws_ecs_cluster.main.id
  description = "ECS cluster ID"
}

output "cluster_arn" {
  value       = aws_ecs_cluster.main.arn
  description = "ECS cluster ARN"
}

output "cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name"
}

output "task_execution_role_arn" {
  value       = aws_iam_role.ecs_task_execution_role.arn
  description = "ECS task execution role ARN"
}

output "task_role_arn" {
  value       = aws_iam_role.ecs_task_role.arn
  description = "ECS task role ARN"
}

output "ecs_security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "ECS tasks security group ID"
}

output "service_arns" {
  value = {
    backend = aws_ecs_service.backend.id
    beat    = aws_ecs_service.beat.id
    worker  = aws_ecs_service.worker.id
  }
  description = "ECS service ARNs"
}

output "ecs_tasks_sg_id" {
  description = "Security group ID used by ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}
