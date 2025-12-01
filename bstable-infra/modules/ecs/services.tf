# Backend Service
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.project}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "backend"
      image = "${var.ecr_repository_urls["backend"]}:${var.image_tag}"
      

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "POSTGRES_SERVER", value = tostring(var.POSTGRES_SERVER) },
        { name = "POSTGRES_PORT", value = tostring(var.POSTGRES_PORT) },
        { name = "POSTGRES_DB", value = tostring(var.POSTGRES_DB) },
        { name = "POSTGRES_USER", value = tostring(var.POSTGRES_USER) },
        { name = "POSTGRES_PASSWORD", value = tostring(var.POSTGRES_PASSWORD) },
        { name = "RABBITMQ_HOST", value = "rabbitmq.${var.project}.${var.environment}.local" },
        { name = "RABBITMQ_PORT", value = "5672" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "backend" {
  name            = "${var.project}-${var.environment}-backend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = var.backend_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "backend"
    container_port   = 80
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_task_execution_role_policy]

  tags = local.common_tags
}

# Beat Service (Celery Beat)
resource "aws_ecs_task_definition" "beat" {
  family                   = "${var.project}-${var.environment}-beat"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.beat_cpu
  memory                   = var.beat_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "beat"
      image = "${var.ecr_repository_urls["beat"]}:${var.image_tag}"

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.beat.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "beat" {
  name            = "${var.project}-${var.environment}-beat"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.beat.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # repeat similarly using .beat[0].arn for beat service, .worker[0].arn for worker service

  tags = local.common_tags
}

# Worker Service (Celery Worker)
resource "aws_ecs_task_definition" "worker" {
  family                   = "${var.project}-${var.environment}-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.worker_cpu
  memory                   = var.worker_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name = "worker"
      image = "${var.ecr_repository_urls["worker"]}:${var.image_tag}"

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.worker.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = local.common_tags
}

resource "aws_ecs_service" "worker" {
  name            = "${var.project}-${var.environment}-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # repeat similarly using .beat[0].arn for beat service, .worker[0].arn for worker service

  tags = local.common_tags
}

# RabbitMQ Task Definition
resource "aws_ecs_task_definition" "rabbitmq" {
  count                    = var.create_rabbitmq ? 1 : 0
  family                   = "${var.project}-${var.environment}-rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = var.rabbitmq_image
      essential = true
      portMappings = [
        { containerPort = 5672, protocol = "tcp" },
        { containerPort = 15672, protocol = "tcp" }
      ]
      environment = [
        { name = "RABBITMQ_DEFAULT_USER", value = var.RABBITMQ_DEFAULT_USER },
        { name = "RABBITMQ_DEFAULT_PASS", value = var.RABBITMQ_DEFAULT_PASS }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-${var.environment}-rabbitmq"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "rabbitmq" {
  count             = var.create_rabbitmq ? 1 : 0
  name              = "/ecs/${var.project}-${var.environment}-rabbitmq"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

# RabbitMQ Service (public subnets, public IP)
resource "aws_ecs_service" "rabbitmq" {
  count           = var.create_rabbitmq ? 1 : 0
  name            = "${var.project}-${var.environment}-rabbitmq"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.rabbitmq[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # RabbitMQ is internal, no ALB, no public IP
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.rabbitmq.id]
    assign_public_ip = false
  }

  # Only service discovery (Cloud Map)
  service_registries {
    registry_arn = aws_service_discovery_service.rabbitmq[0].arn
  }

  tags = local.common_tags
}


