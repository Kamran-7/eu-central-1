# Core
project     = "bstable"
environment = "dev"
aws_region  = "us-east-1"

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_count  = 2
private_subnet_count = 3

# ECR
repositories               = ["backend", "beat", "worker"]
image_retention_count      = 5
expire_untagged_after_days = 7
kms_key_arn                = null # dev: AES256 is fine

# ECS
enable_autoscaling    = false
backend_desired_count = 1
worker_desired_count  = 1
log_retention_days    = 3

# image_tag           = "build-123"  # ignored when overrides are set

# RDS
# dev.tfvars
db_engine         = "postgres"
db_engine_version = "16.6"
db_subnet_cidrs   = ["10.0.5.0/24", "10.0.6.0/24"]
# (db_engine/version/name/username use defaults)
# RDS → CloudWatch engine logs (PostgreSQL example)
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

# Retention for those log groups
rds_log_retention_days = 7

enable_alarms = false
alert_emails  = [] # keep empty in dev


