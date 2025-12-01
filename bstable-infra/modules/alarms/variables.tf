variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "alert_emails" {
  type    = list(string)
  default = []
}

# ---------------------
# ALB / Target Group
# ---------------------
variable "alb_arn_suffix" {
  type = string
  # from aws_lb.main.arn_suffix
}

variable "target_group_arn_suffix" {
  type = string
  # from aws_lb_target_group.backend.arn_suffix
}

variable "alb_5xx_rate_threshold" {
  type    = number
  default = 1
}

variable "alb_eval_periods" {
  type    = number
  default = 3
}

variable "alb_period" {
  type    = number
  default = 60
}

# ---------------------
# ECS
# ---------------------
variable "ecs_cluster_name" {
  type = string
}

variable "ecs_services" {
  type = list(string)
  # Example: ["bstable-prod-backend", "bstable-prod-worker"]
}

variable "ecs_cpu_high_threshold" {
  type    = number
  default = 80
}

variable "ecs_mem_high_threshold" {
  type    = number
  default = 85
}

variable "ecs_eval_periods" {
  type    = number
  default = 3
}

variable "ecs_period" {
  type    = number
  default = 60
}

# ---------------------
# RDS
# ---------------------
variable "rds_identifier" {
  type = string
  # e.g., "bstable-prod-db"
}

variable "rds_cpu_high_threshold" {
  type    = number
  default = 80
}

variable "rds_conn_high_threshold" {
  type    = number
  default = 200
}

variable "rds_eval_periods" {
  type    = number
  default = 5
}

variable "rds_period" {
  type    = number
  default = 60
}

# --- ALB 4xx ---
variable "alb_4xx_rate_threshold" {
  description = "Alarm when ALB 4xx error rate (%) >= threshold."
  type        = number
  default     = 2
}

# --- RDS free space / memory (thresholds in human units) ---
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
