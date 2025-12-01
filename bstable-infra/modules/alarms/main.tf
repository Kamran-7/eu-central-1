resource "aws_sns_topic" "alerts" {
  name = "${var.project}-${var.environment}-alerts"
  tags = var.tags
}

# Optional email subscription (can be empty in prod; use ChatOps instead)
resource "aws_sns_topic_subscription" "email" {
  count     = length(var.alert_emails)
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_emails[count.index]
}

# 5XXError% = (HTTPCode_ELB_5XX_Count / RequestCount) * 100
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx-rate"
  alarm_description   = "ALB 5xx rate > ${var.alb_5xx_rate_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alb_5xx_rate_threshold
  evaluation_periods  = var.alb_eval_periods
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "req"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = var.alb_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix # e.g. app/bstable-prod-alb/123456...
      }
    }
  }

  metric_query {
    id          = "err5xx"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_5XX_Count"
      period      = var.alb_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id          = "rate"
    return_data = true
    expression  = "IF(req>0, (err5xx/req)*100, 0)"
    label       = "ALB 5xx Rate %"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# CPU alarm per service
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  for_each            = toset(var.ecs_services)
  alarm_name          = "${var.project}-${var.environment}-${each.value}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.ecs_cpu_high_threshold
  evaluation_periods  = var.ecs_eval_periods
  period              = var.ecs_period
  statistic           = "Average"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# Memory alarm per service
resource "aws_cloudwatch_metric_alarm" "ecs_mem_high" {
  for_each            = toset(var.ecs_services)
  alarm_name          = "${var.project}-${var.environment}-${each.value}-mem-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.ecs_mem_high_threshold
  evaluation_periods  = var.ecs_eval_periods
  period              = var.ecs_period
  statistic           = "Average"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  treat_missing_data  = "notBreaching"
  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = each.value
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}


# CPU utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "${var.project}-${var.environment}-rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_cpu_high_threshold
  evaluation_periods  = var.rds_eval_periods
  period              = var.rds_period
  statistic           = "Average"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# DatabaseConnections
resource "aws_cloudwatch_metric_alarm" "rds_conn_high" {
  alarm_name          = "${var.project}-${var.environment}-rds-db-connections-high"
  comparison_operator = "GreaterThanThreshold"
  threshold           = var.rds_conn_high_threshold
  evaluation_periods  = var.rds_eval_periods
  period              = var.rds_period
  statistic           = "Average"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  treat_missing_data  = "notBreaching"
  dimensions = {
    DBInstanceIdentifier = var.rds_identifier
  }
  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# 4XXError% = (HTTPCode_ELB_4XX_Count / RequestCount) * 100
resource "aws_cloudwatch_metric_alarm" "alb_4xx_rate" {
  alarm_name          = "${var.project}-${var.environment}-alb-4xx-rate"
  alarm_description   = "ALB 4xx rate >= ${var.alb_4xx_rate_threshold}%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = var.alb_4xx_rate_threshold
  evaluation_periods  = var.alb_eval_periods
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "req"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "RequestCount"
      period      = var.alb_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id          = "err4xx"
    return_data = false
    metric {
      namespace   = "AWS/ApplicationELB"
      metric_name = "HTTPCode_ELB_4XX_Count"
      period      = var.alb_period
      stat        = "Sum"
      dimensions = {
        LoadBalancer = var.alb_arn_suffix
      }
    }
  }

  metric_query {
    id          = "rate"
    return_data = true
    expression  = "IF(req>0, (err4xx/req)*100, 0)"
    label       = "ALB 4xx Rate %"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# RDS FreeStorageSpace in GB (<= threshold)
resource "aws_cloudwatch_metric_alarm" "rds_free_storage_low" {
  alarm_name          = "${var.project}-${var.environment}-rds-free-storage-low"
  alarm_description   = "RDS FreeStorageSpace <= ${var.rds_free_storage_threshold_gb} GB"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.rds_free_storage_threshold_gb
  evaluation_periods  = var.rds_eval_periods
  treat_missing_data  = "breaching"

  # Metric math: convert bytes -> GB
  metric_query {
    id          = "bytes"
    return_data = false
    metric {
      namespace   = "AWS/RDS"
      metric_name = "FreeStorageSpace"
      period      = var.rds_period
      stat        = "Average"
      dimensions = {
        DBInstanceIdentifier = var.rds_identifier
      }
    }
  }

  metric_query {
    id          = "gb"
    return_data = true
    expression  = "bytes/1073741824"
    label       = "FreeStorageSpace(GB)"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

# RDS FreeableMemory in MB (<= threshold)
resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  alarm_name          = "${var.project}-${var.environment}-rds-freeable-memory-low"
  alarm_description   = "RDS FreeableMemory <= ${var.rds_freeable_memory_threshold_mb} MB"
  comparison_operator = "LessThanOrEqualToThreshold"
  threshold           = var.rds_freeable_memory_threshold_mb
  evaluation_periods  = var.rds_eval_periods
  treat_missing_data  = "breaching"

  # Metric math: bytes -> MB
  metric_query {
    id          = "bytes"
    return_data = false
    metric {
      namespace   = "AWS/RDS"
      metric_name = "FreeableMemory"
      period      = var.rds_period
      stat        = "Average"
      dimensions = {
        DBInstanceIdentifier = var.rds_identifier
      }
    }
  }

  metric_query {
    id          = "mb"
    return_data = true
    expression  = "bytes/1048576"
    label       = "FreeableMemory(MB)"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
  tags          = var.tags
}

