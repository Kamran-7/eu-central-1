# --- ALB Security Group ---
resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for ${var.project} ${var.environment} ALB"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.project}-${var.environment}-alb-sg" }
  )
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from anywhere"
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
  security_group_id = aws_security_group.alb.id
}

# --- ALB ---
resource "aws_lb" "main" {
  name                       = "${var.project}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.public_subnet_ids
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  idle_timeout               = 60

  tags = merge(
    local.common_tags,
    { Name = "${var.project}-${var.environment}-alb" }
  )
}

# --- Target Group (Fargate requires target_type = ip) ---
resource "aws_lb_target_group" "backend" {
  # Use name_prefix so create_before_destroy can succeed (unique name)
  name_prefix          = substr("${var.project}-${var.environment}-tg-", 0, 6) # TG prefix max 6 chars; AWS adds random suffix
  vpc_id               = var.vpc_id
  port                 = 80
  protocol             = "HTTP"
  target_type          = "ip" # <<< REQUIRED for Fargate (awsvpc)
  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/docs" # change to "/health" if your app exposes it
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    local.common_tags,
    { Name = "${var.project}-${var.environment}-tg" }
  )
}

# --- HTTP Listener ---
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# modules/alb/main.tf (add alongside your 80 rule)
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS (prep for future ACM/443 listener)"
  security_group_id = aws_security_group.alb.id
}
