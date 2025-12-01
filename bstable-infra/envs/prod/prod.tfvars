# Core
project     = "bstable"
environment = "prod"
aws_region  = "us-east-1"

# Networking
vpc_cidr             = "192.168.0.0/16"
public_subnet_count  = 3
private_subnet_count = 3

# RDS (prod VPC must have its own DB subnets in 2 AZs)
db_engine         = "postgres"
db_engine_version = "16.6"
db_subnet_cidrs   = ["192.168.5.0/24", "192.168.6.0/24"]
POSTGRES_DB       = "prod-bstable-db"
POSTGRES_USER     = "prod_user"


# RDS → CloudWatch (engine logs) + Enhanced Monitoring + PI
enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
rds_log_retention_days          = 14
rds_monitoring_interval         = 15
rds_enhanced_retention_days     = 14
performance_insights_enabled    = true
#performance_insights_kms_key_id = null  # (optional) set your CMK ARN if required

# ECR
repositories               = ["backend", "beat", "worker"]
image_retention_count      = 10 # prod: keep a bit more
expire_untagged_after_days = 7
kms_key_arn                = null # (recommended: use a CMK in prod when ready)

# ECS
enable_autoscaling    = true
backend_desired_count = 1
worker_desired_count  = 1
log_retention_days    = 14

# RabbitMQ service (public image in public subnets)
create_rabbitmq    = true
rabbitmq_image     = "public.ecr.aws/docker/library/rabbitmq:4.0-management"
RABBITMQ_DEFAULT_USER      = "prod-queue"

enable_alarms           = true
alert_emails            = ["kamran.sharief@signiance.com"]
alb_5xx_rate_threshold  = 1
ecs_cpu_high_threshold  = 75
ecs_mem_high_threshold  = 80
rds_conn_high_threshold = 500

alb_4xx_rate_threshold           = 1
rds_free_storage_threshold_gb    = 10
rds_freeable_memory_threshold_mb = 512

enable_service_discovery = true


# IMPORTANT (Prod): No image overrides here — CI/CD will push your real images to ECR
# backend_image_override = ""
# beat_image_override    = ""
# worker_image_override  = ""
