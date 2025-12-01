variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "project" {
  type        = string
  description = "Project name"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

################### vpc ########################
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
  default     = 2
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
  default     = 3
}

variable "enable_autoscaling" {
  type        = bool
  description = "Enable ECS autoscaling"
  default     = false
}

variable "backend_desired_count" {
  type        = number
  description = "Backend service desired count"
  default     = 1
}

variable "worker_desired_count" {
  type        = number
  description = "Worker service desired count"
  default     = 1
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention days"
  default     = 7
}

variable "image_tag" {
  type    = string
  default = "latest"
  validation {
    condition     = length(trimspace(var.image_tag)) > 0
    error_message = "image_tag cannot be empty."
  }
}


################### ECR ########################
variable "repositories" {
  description = "Logical repository names to create (simple list)."
  type        = list(string)
  default     = ["backend", "beat", "worker"]
}

variable "image_retention_count" {
  description = "Keep last N images (any tag) via lifecycle policy."
  type        = number
  default     = 5
  validation {
    condition     = var.image_retention_count >= 1
    error_message = "image_retention_count must be >= 1."
  }
}

variable "expire_untagged_after_days" {
  description = "Purge untagged images older than X days via lifecycle policy."
  type        = number
  default     = 7
  validation {
    condition     = var.expire_untagged_after_days >= 1
    error_message = "expire_untagged_after_days must be >= 1."
  }
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for ECR encryption (null uses AES256)."
  type        = string
  default     = null
}

################### Databse ########################
variable "db_subnet_cidrs" {
  type        = list(string)
  description = "DB subnet CIDRs (two AZs)"
  default     = [] # <— prevents prompting
}


# Optional: DB engine params (defaults for Postgres)
variable "db_engine" {
  type    = string
  default = "postgres"
}

variable "db_engine_version" {
  type    = string
  default = "15.4"
}

# App env (use exact names app expects) - will be passed to ECS

variable "POSTGRES_PORT" {
  type        = string
  description = "DB port as string for container env"
  default     = "5432"
}

variable "POSTGRES_DB" {
  type        = string
  description = "Application DB name"
}

variable "POSTGRES_USER" {
  type        = string
  description = "Application DB user"
}

variable "POSTGRES_PASSWORD" {
  type        = string
  sensitive   = true
  description = "Application DB password (put in *.secrets.tfvars)"
}

# RDS → CloudWatch logs (engine logs)
variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = []
  description = "RDS engine logs to export to CloudWatch (e.g., [\"postgresql\",\"upgrade\"])."
}

variable "rds_log_retention_days" {
  type        = number
  default     = 7
  description = "CloudWatch log retention for RDS engine logs"
}

variable "rds_monitoring_interval" {
  type    = number
  default = 15
}

variable "rds_enhanced_retention_days" {
  type    = number
  default = 14
}
variable "performance_insights_enabled" {
  type    = bool
  default = true
}

################### RabbitMQ ########################
variable "create_rabbitmq" {
  type    = bool
  default = true
}

variable "rabbitmq_image" {
  type    = string
  default = "public.ecr.aws/docker/library/rabbitmq:4.0-management"
}
variable "RABBITMQ_DEFAULT_USER" {
  type    = string
  default = "prod-queue"
}

variable "RABBITMQ_DEFAULT_PASS" {
  type      = string
  sensitive = true
}

# ---- Alerts / SNS recipients ----
variable "alert_emails" {
  description = "Email recipients for SNS notifications (can be empty; add Slack/Lambda subscriptions separately)."
  type        = list(string)
  default     = []
}

# ---- ALB alarm tuning ----
variable "alb_5xx_rate_threshold" {
  description = "Alarm when ALB 5xx error rate (%) >= threshold."
  type        = number
  default     = 1
}
variable "alb_eval_periods" {
  description = "ALB 5xx evaluation periods."
  type        = number
  default     = 3
}
variable "alb_period" {
  description = "ALB metric period (seconds)."
  type        = number
  default     = 60
}

# ---- ECS alarm tuning ----
variable "ecs_cpu_high_threshold" {
  description = "Alarm when ECS service CPUUtilization (%) >= threshold."
  type        = number
  default     = 80
}
variable "ecs_mem_high_threshold" {
  description = "Alarm when ECS service MemoryUtilization (%) >= threshold."
  type        = number
  default     = 85
}
variable "ecs_eval_periods" {
  description = "ECS evaluation periods."
  type        = number
  default     = 3
}
variable "ecs_period" {
  description = "ECS metric period (seconds)."
  type        = number
  default     = 60
}

# ---- RDS alarm tuning ----
variable "rds_cpu_high_threshold" {
  description = "Alarm when RDS CPUUtilization (%) >= threshold."
  type        = number
  default     = 80
}
variable "rds_conn_high_threshold" {
  description = "Alarm when RDS DatabaseConnections >= threshold."
  type        = number
  default     = 200
}
variable "rds_eval_periods" {
  description = "RDS evaluation periods."
  type        = number
  default     = 5
}
variable "rds_period" {
  description = "RDS metric period (seconds)."
  type        = number
  default     = 60
}

variable "enable_alarms" {
  description = "Create CloudWatch alarms and SNS notifications"
  type        = bool
  default     = false
}

variable "alb_4xx_rate_threshold" {
  description = "Alarm when ALB 4xx error rate (%) >= threshold."
  type        = number
  default     = 2
}

variable "rds_free_storage_threshold_gb" {
  description = "Alarm when RDS FreeStorageSpace (GB) <= threshold."
  type        = number
  default     = 5
}

variable "rds_freeable_memory_threshold_mb" {
  description = "Alarm when RDS FreeableMemory (MB) <= threshold."
  type        = number
  default     = 256
}
