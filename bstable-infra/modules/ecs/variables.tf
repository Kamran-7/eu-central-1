variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs"
}

variable "alb_security_group_id" {
  type        = string
  description = "ALB security group ID"
}

variable "target_group_arn" {
  type        = string
  description = "ALB target group ARN"
}

variable "ecr_repository_urls" {
  type        = map(string)
  description = "ECR repository URLs"
}

# Autoscaling
variable "enable_autoscaling" {
  type        = bool
  description = "Enable autoscaling (prod only)"
  default     = false
}

# Backend service
variable "backend_cpu" {
  type        = number
  description = "Backend CPU units"
  default     = 256
}

variable "backend_memory" {
  type        = number
  description = "Backend memory (MB)"
  default     = 512
}

variable "backend_desired_count" {
  type        = number
  description = "Backend desired task count"
  default     = 1
}

variable "backend_min_capacity" {
  type        = number
  description = "Backend minimum capacity"
  default     = 1
}

variable "backend_max_capacity" {
  type        = number
  description = "Backend maximum capacity"
  default     = 10
}

variable "backend_cpu_target" {
  type        = number
  description = "Backend CPU target for autoscaling"
  default     = 70
}

# Beat service
variable "beat_cpu" {
  type        = number
  description = "Beat CPU units"
  default     = 256
}

variable "beat_memory" {
  type        = number
  description = "Beat memory (MB)"
  default     = 512
}

# Worker service
variable "worker_cpu" {
  type        = number
  description = "Worker CPU units"
  default     = 256
}

variable "worker_memory" {
  type        = number
  description = "Worker memory (MB)"
  default     = 512
}

variable "worker_desired_count" {
  type        = number
  description = "Worker desired task count"
  default     = 1
}

variable "worker_min_capacity" {
  type        = number
  description = "Worker minimum capacity"
  default     = 1
}

variable "worker_max_capacity" {
  type        = number
  description = "Worker maximum capacity"
  default     = 10
}

variable "worker_cpu_target" {
  type        = number
  description = "Worker CPU target for autoscaling"
  default     = 70
}

# Logging
variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention days"
  default     = 7
}

# Service Discovery

variable "image_tag" {
  type        = string
  description = "Docker image tag (build number)"
  default     = "v1.0.0"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#Database details not using secrets manager for now
variable "POSTGRES_SERVER" {
  type = string
}
variable "POSTGRES_PORT" {
  type = number
}
variable "POSTGRES_DB" {
  type = string
}
variable "POSTGRES_USER" {
  type = string
}
variable "POSTGRES_PASSWORD" {
  type      = string
  sensitive = true
}
variable "create_rabbitmq" {
  type    = bool
  default = true
}
variable "rabbitmq_image" {
  type    = string
  default = "public.ecr.aws/docker/library/rabbitmq:4.0-management"
}

# RabbitMQ env (non-secret good defaults)
variable "RABBITMQ_DEFAULT_USER" {
  type        = string
  default     = "bstable-queue"
  description = "RABBITMQ_DEFAULT_USER"
}

# Sensitive
variable "RABBITMQ_DEFAULT_PASS" {
  type        = string
  sensitive   = true
  description = "RABBITMQ_DEFAULT_PASS"
}

# Public management UI ingress CIDR (restrict to your office IP ideally)
variable "rabbitmq_mgmt_cidr" {
  type    = list(string)
  default = ["0.0.0.0/0"] # tighten in prod (e.g., ["203.0.113.0/24"])
}

variable "enable_service_discovery" {
  type        = bool
  default     = true
  description = "Create Cloud Map private DNS and register services"
}

variable "service_discovery_namespace" {
  type        = string
  default     = "" # empty = auto: "<project>.<environment>.local"
  description = "Override Cloud Map private DNS namespace (optional)"
}

