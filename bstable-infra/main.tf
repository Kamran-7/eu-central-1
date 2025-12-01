module "vpc" {
  source = "./modules/vpc"

  project              = var.project
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count

  db_subnet_cidrs = var.db_subnet_cidrs
  tags            = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  project           = var.project
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  tags              = local.common_tags
}
################### ECR ########################
module "ecr" {
  source = "./modules/ecr"

  project     = var.project
  environment = var.environment
  for_each    = toset(var.repositories) # keys are: backend, beat, worker

  # final repo name: project-environment-<repo>
  name = "${var.environment}-${var.project}-${each.value}" # dev-bstable-backend


  # env-safe defaults
  image_tag_mutability = lower(var.environment) == "prod" ? "IMMUTABLE" : "MUTABLE"
  force_delete         = lower(var.environment) == "prod" ? false : true
  protect_from_destroy = lower(var.environment) == "prod" ? true : false

  # encryption
  encryption_type = var.kms_key_arn == null ? "AES256" : "KMS"
  kms_key_arn     = var.kms_key_arn


  enable_keep_last_n    = true
  keep_last_n           = var.image_retention_count
  enable_purge_untagged = true
  purge_untagged_days   = var.expire_untagged_after_days

  scan_on_push = true
  tags         = merge(local.common_tags, { Service = each.value })

  # --- Collect ECR outputs into simple maps keyed by repo ("backend","beat","worker") ---

}

# Cache public.ecr.aws images under your private ECR at prefix "ecr-public"
resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

locals {
  # keys: backend | beat | worker ; values: full ECR repo URLs
  ecr_repository_urls = { for key, m in module.ecr : key => m.repository_url }

  # (optional, if you need them later)
  ecr_repository_names = { for key, m in module.ecr : key => m.repository_name }
  ecr_repository_arns  = { for key, m in module.ecr : key => m.repository_arn }
}

################### ECS ########################

module "ecs" {
  source = "./modules/ecs"

  project               = var.project
  environment           = var.environment
  aws_region            = var.aws_region
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_arn
  ecr_repository_urls   = local.ecr_repository_urls
  enable_autoscaling    = var.enable_autoscaling
  backend_desired_count = var.backend_desired_count
  worker_desired_count  = var.worker_desired_count
  log_retention_days    = var.log_retention_days
  image_tag             = var.image_tag
  tags                  = local.common_tags

  enable_service_discovery    = true
  service_discovery_namespace = ""
  POSTGRES_SERVER             = module.rds.endpoint
  POSTGRES_PORT               = tostring(module.rds.port)
  POSTGRES_DB                 = var.POSTGRES_DB
  POSTGRES_USER               = var.POSTGRES_USER
  POSTGRES_PASSWORD           = var.POSTGRES_PASSWORD

  # Rabbit
  create_rabbitmq    = var.create_rabbitmq
  rabbitmq_image     = var.rabbitmq_image
  RABBITMQ_DEFAULT_USER  = var.RABBITMQ_DEFAULT_USER
  RABBITMQ_DEFAULT_PASS = var.RABBITMQ_DEFAULT_PASS
  
}

# SG for RDS instance
resource "aws_security_group" "rds" {
  name        = "${var.project}-${var.environment}-rds-sg"
  description = "RDS SG for ${var.project} ${var.environment}"
  vpc_id      = module.vpc.vpc_id

  # Allow all egress (responses / AWS APIs)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project}-${var.environment}-rds-sg" })
}

# Allow ECS tasks to reach RDS (Postgres 5432; use 3306 for MySQL)
resource "aws_security_group_rule" "rds_ingress_from_ecs" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = module.ecs.ecs_tasks_sg_id
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  description              = "Allow DB from ECS tasks SG"
}

################### RDS ########################
module "rds" {
  source = "./modules/rds-server" # path to your posted module

  identifier     = "${var.project}-${var.environment}-db"
  engine         = var.db_engine         # "postgres" by default
  engine_version = var.db_engine_version # "15.4" by default
  instance_class = "db.t3.micro"         # dev-sized

  # Dev DB details (no Secrets Manager for now)
  db_name  = var.POSTGRES_DB
  username = var.POSTGRES_USER
  password = var.POSTGRES_PASSWORD



  # Put DB in private subnets (your 10.0.5.0/24 and 10.0.6.0/24)
  create_db_subnet_group = true
  subnet_ids             = module.vpc.db_subnet_ids

  # Only reachable from ECS tasks SG (and later from VPN CIDR if you add a rule)
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Private RDS
  publicly_accessible = false
  multi_az            = false # dev

  # Minimal storage/ops for dev
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  backup_retention_period = 1
  preferred_backup_window = "03:00-04:00"
  maintenance_window      = "Sun:04:00-Sun:05:00"

  deletion_protection = false
  apply_immediately   = true

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  rds_log_retention_days          = var.rds_log_retention_days

  rds_monitoring_interval      = var.rds_monitoring_interval
  rds_enhanced_retention_days  = var.rds_enhanced_retention_days
  performance_insights_enabled = var.performance_insights_enabled

  # let your module derive param group where possible
  parameter_group_family = null
  create_option_group    = false

  kms_key_id                      = null
  performance_insights_kms_key_id = null

  tags = local.common_tags
}

module "alarms" {
  count        = var.enable_alarms ? 1 : 0
  source       = "./modules/alarms"
  project      = var.project
  environment  = var.environment
  tags         = local.common_tags
  alert_emails = var.alert_emails # from tfvars; can be []

  # ALB/TG (use arn_suffix outputs from your alb module)
  alb_arn_suffix          = module.alb.alb_arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix

  # ECS (cluster name + list of service names)
  ecs_cluster_name = module.ecs.cluster_name
  ecs_services = ["bstable-${var.environment}-backend",
    "bstable-${var.environment}-beat",
  "bstable-${var.environment}-worker"]

  # RDS (db identifier used in the module call)
  rds_identifier = "${var.project}-${var.environment}-db"

  # Optional overrides (or keep defaults)
  alb_5xx_rate_threshold           = 1
  ecs_cpu_high_threshold           = 80
  ecs_mem_high_threshold           = 85
  rds_cpu_high_threshold           = 80
  rds_conn_high_threshold          = 200
  alb_4xx_rate_threshold           = var.alb_4xx_rate_threshold
  rds_free_storage_threshold_gb    = var.rds_free_storage_threshold_gb
  rds_freeable_memory_threshold_mb = var.rds_freeable_memory_threshold_mb

}

