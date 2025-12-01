############################################
# Locals (engine → port, family, password)
############################################
locals {
  port_map = {
    mysql     = 3306
    postgres  = 5432
    mariadb   = 3306
    sqlserver = 1433
    oracle    = 1521
  }

  # Resolve port (handles prefix engines like sqlserver-*, oracle-*)
  resolved_port = (
    startswith(var.engine, "sqlserver-") ? local.port_map.sqlserver :
    startswith(var.engine, "oracle-") ? local.port_map.oracle :
    lookup(local.port_map, var.engine, 5432)
  )

  # Major version (e.g., "8.0.35" -> "8", "15.4" -> "15")
  engine_major = regex("^\\d+", var.engine_version)

  # Derive parameter group family when it's safe.
  # - mysql/postgres/mariadb → inferred
  # - sqlserver-*/oracle-*   → must be provided explicitly
  derived_family = (
    var.parameter_group_family != null ? var.parameter_group_family :
    (
      var.engine == "mysql" ? "mysql${local.engine_major}" :
      var.engine == "postgres" ? "postgres${local.engine_major}" :
      var.engine == "mariadb" ? "mariadb${local.engine_major}" :
      null
    )
  )

  create_password = var.password == null


}

############################################
# Input validations (fail fast)
############################################

resource "null_resource" "validate" {
  lifecycle {
    # Must either create a DB subnet group OR provide an existing name
    precondition {
      condition     = var.create_db_subnet_group || (var.db_subnet_group_name != null && var.db_subnet_group_name != "")
      error_message = "Either set create_db_subnet_group=true (with subnet_ids), or provide db_subnet_group_name."
    }

    # Parameter group family must be known:
    # - mysql/postgres/mariadb can be derived
    # - sqlserver-*/oracle-* must be provided explicitly
    precondition {
      condition     = local.derived_family != null
      error_message = "parameter_group_family is required for engine '${var.engine}'. Provide it for sqlserver-* (e.g. sqlserver-ee-15.0) and oracle-* (e.g. oracle-se2-19)."
    }

    # db_name is ignored by SQL Server / Oracle
    precondition {
      condition     = !(startswith(var.engine, "sqlserver-") || startswith(var.engine, "oracle-")) || var.db_name == null
      error_message = "db_name is ignored by SQL Server / Oracle. Leave it null."
    }
  }
}



############################################
# Password (only if not supplied)
############################################
resource "random_password" "this" {
  count   = local.create_password ? 1 : 0
  length  = 20
  special = true
}

############################################
# Optional Subnet Group (private subnets recommended)
############################################
resource "aws_db_subnet_group" "this" {
  count      = var.create_db_subnet_group ? 1 : 0
  name       = "${var.identifier}-subnets" # <— sanitized
  subnet_ids = var.subnet_ids
  tags       = merge(var.tags, { Name = "${var.identifier}-subnets" })
}

############################################
# Parameter & Option groups
############################################
resource "aws_db_parameter_group" "this" {
  name   = "${var.identifier}-pg" # <— sanitized
  family = local.derived_family
  tags   = merge(var.tags, { Name = "${var.identifier}-pg" })
}

# Option group (if you create one)
resource "aws_db_option_group" "this" {
  count                = var.create_option_group ? 1 : 0
  name                 = "${var.identifier}-og" # <— sanitized
  engine_name          = var.engine
  major_engine_version = regex("^\\d+", var.engine_version)
  tags                 = merge(var.tags, { Name = "${var.identifier}-og" })
}

############################################
# RDS Instance
############################################
locals {
  subnet_group_name = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  master_password   = var.password != null ? var.password : try(random_password.this[0].result, null)
}

############################################
# # IAM role for RDS Enhanced Monitoring
############################################

resource "aws_iam_role" "rds_monitoring" {
  name = "${var.identifier}-rds-monitoring-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "monitoring.rds.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_attach" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Optional: explicit log group for RDSOSMetrics (to control retention)
resource "aws_cloudwatch_log_group" "rds_enhanced" {
  name              = "/aws/rds/instance/${var.identifier}/RDSOSMetrics"
  retention_in_days = var.rds_enhanced_retention_days
  tags              = var.tags
}

# In your aws_db_instance.this block, ensure:
#   monitoring_interval + monitoring_role_arn + performance_insights_enabled
#performance_insights_enabled already set at module level

resource "aws_db_instance" "this" {
  identifier     = var.identifier
  engine         = var.engine # e.g. mysql | postgres | mariadb | sqlserver-ee | oracle-se2
  engine_version = var.engine_version
  instance_class = var.instance_class

  db_name  = (startswith(var.engine, "sqlserver-") || startswith(var.engine, "oracle-")) ? null : var.db_name
  username = var.username
  password = local.master_password
  port     = local.resolved_port

  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = local.subnet_group_name

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type

  multi_az            = var.multi_az
  publicly_accessible = var.publicly_accessible

  storage_encrypted = true
  kms_key_id        = var.kms_key_id

  backup_retention_period = var.backup_retention_period
  backup_window           = var.preferred_backup_window
  maintenance_window      = var.maintenance_window

  deletion_protection = var.deletion_protection
  apply_immediately   = var.apply_immediately

  parameter_group_name = aws_db_parameter_group.this.name
  option_group_name    = var.create_option_group ? aws_db_option_group.this[0].name : null

  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  monitoring_interval             = var.rds_monitoring_interval
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn




  # Licensing for SQL Server / Oracle
  license_model = (startswith(var.engine, "sqlserver-") || startswith(var.engine, "oracle-")) ? var.license_model : null

  final_snapshot_identifier = "${var.identifier}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  skip_final_snapshot = true


  tags = var.tags
}

# Build full CW log group names from exports
locals {
  rds_engine_log_group_names = toset([
    for name in var.enabled_cloudwatch_logs_exports :
    "/aws/rds/instance/${var.identifier}/${name}"
  ])
}

resource "aws_cloudwatch_log_group" "rds_engine_logs" {
  for_each          = local.rds_engine_log_group_names
  name              = each.value
  retention_in_days = var.rds_log_retention_days
  tags              = var.tags

  # Ensure DB exists first (so AWS has context to create/own the stream)
  depends_on = [aws_db_instance.this]
}
