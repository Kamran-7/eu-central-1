locals {
  sd_namespace = var.service_discovery_namespace != "" ? var.service_discovery_namespace : "${var.project}.${var.environment}.local"
}

resource "aws_service_discovery_private_dns_namespace" "ns" {
  count = var.enable_service_discovery ? 1 : 0
  name  = local.sd_namespace
  vpc   = var.vpc_id
  tags  = local.common_tags
}

resource "aws_service_discovery_service" "rabbitmq" {
  count = var.enable_service_discovery ? 1 : 0
  name  = "rabbitmq"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ns[0].id
    dns_records {
      type = "A"
      ttl  = 10
    }
    routing_policy = "WEIGHTED"
  }
  health_check_custom_config { failure_threshold = 1 }
  tags = local.common_tags
}

resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = local.common_tags
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-${var.environment}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-ecs-tasks-sg"
    }
  )
}

# Security Group for RabbitMQ service (public subnets)
resource "aws_security_group" "rabbitmq" {
  name        = "${var.project}-${var.environment}-rabbitmq-sg"
  description = "RabbitMQ Service SG"
  vpc_id      = var.vpc_id
  tags        = merge(local.common_tags, { Name = "${var.project}-${var.environment}-rabbitmq-sg" })
}

# Allow AMQP 5672 from ECS tasks only
resource "aws_security_group_rule" "rabbitmq_amqp_from_ecs" {
  type                     = "ingress"
  from_port                = 5672
  to_port                  = 5672
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rabbitmq.id
  source_security_group_id = aws_security_group.ecs_tasks.id
  description              = "AMQP from ECS tasks"
}

# Allow mgmt UI 15672 from a controlled CIDR list (tighten this!)
resource "aws_security_group_rule" "rabbitmq_mgmt" {
  type              = "ingress"
  from_port         = 15672
  to_port           = 15672
  protocol          = "tcp"
  security_group_id = aws_security_group.rabbitmq.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "RabbitMQ mgmt UI"
  depends_on        = [aws_security_group.rabbitmq] # reduce race conditions
}

# Egress all
resource "aws_security_group_rule" "rabbitmq_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.rabbitmq.id
  cidr_blocks       = ["0.0.0.0/0"]
}
