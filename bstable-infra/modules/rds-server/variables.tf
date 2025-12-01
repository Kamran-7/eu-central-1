variable "identifier" {
  description = "Lowercase name base for RDS resources; only [a-z0-9.-] allowed"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]+$", var.identifier))
    error_message = "identifier must be lowercase and contain only letters, digits, periods, and hyphens (e.g., 'orders-prod-db')."
  }
}

variable "engine" {
  description = "Single-instance RDS engine (Aurora is separate)."
  type        = string
  # Accepts: mysql | postgres | mariadb | sqlserver-* | oracle-*
  validation {
    condition     = can(regex("^(mysql|postgres|mariadb|sqlserver-.+|oracle-.+)$", var.engine))
    error_message = "Use a single-instance engine: mysql, postgres, mariadb, sqlserver-*, or oracle-* (Aurora is not supported in this module)."
  }
}

variable "engine_version" {
  description = "Engine version (e.g., MySQL 8.0.35, Postgres 15.4, SQL Server 15.00.xxxx.x)"
  type        = string
}

variable "instance_class" {
  description = "DB instance class (e.g., db.m6g.large, db.m5.large)"
  type        = string
}

variable "db_name" {
  description = "Initial DB name (ignored for sqlserver)"
  type        = string
  default     = null
}

variable "username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "password" {
  description = "Master password (leave null to auto-generate)"
  type        = string
  default     = null
  sensitive   = true
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 50
}

variable "max_allocated_storage" {
  description = "Upper bound for autoscaling storage (0 disables)"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "gp3 | gp2 | io1"
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "publicly_accessible" {
  type    = bool
  default = false
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "preferred_backup_window" {
  type    = string
  default = "02:00-03:00"
}

variable "maintenance_window" {
  type    = string
  default = "sun:03:00-sun:04:00"
}

variable "kms_key_id" {
  description = "KMS Key ARN for storage encryption (null = AWS managed)"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  type    = bool
  default = true
}

variable "performance_insights_kms_key_id" {
  type    = string
  default = null
}

variable "apply_immediately" {
  type    = bool
  default = false
}

# Networking (you already manage these)
variable "vpc_security_group_ids" {
  description = "Existing SG IDs to attach to the instance"
  type        = list(string)
}

# Subnet group (you may already have one; otherwise allow create)
variable "create_db_subnet_group" {
  type    = bool
  default = false
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group name (required if not creating)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnets used when creating subnet group (private recommended)"
  type        = list(string)
  default     = []
}

# Parameter & Option groups
variable "parameter_group_family" {
  description = "Override family; auto-derived if null"
  type        = string
  default     = null
}

variable "create_option_group" {
  description = "Create an option group (useful for SQL Server features)"
  type        = bool
  default     = false
}

# SQL Server specifics
variable "license_model" {
  description = "license-included | bring-your-own-license (SQL Server only)"
  type        = string
  default     = "license-included"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch Logs (e.g., postgres:['postgresql','upgrade'])"
  type        = list(string)
  default     = []
}

variable "rds_log_retention_days" {
  type        = number
  default     = 14
  description = "CloudWatch retention for RDS engine logs"
}

variable "rds_monitoring_interval" {
  type        = number
  default     = 15
  description = "Enhanced monitoring interval in seconds (1,5,10,15,30,60)"
}

variable "rds_enhanced_retention_days" {
  type        = number
  default     = 14
  description = "CW Logs retention for RDS Enhanced Monitoring"
}
