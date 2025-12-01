########################################
# ECR repository (choose one via count)
########################################

# Protected repo (e.g., prod) – lifecycle prevent_destroy = true
resource "aws_ecr_repository" "protected" {
  count                = var.protect_from_destroy ? 1 : 0
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? var.encryption_type : "KMS"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration { scan_on_push = var.scan_on_push }
  tags = var.tags

  lifecycle {
    prevent_destroy = false
  }
}

# Unprotected repo (e.g., dev)
resource "aws_ecr_repository" "unprotected" {
  count                = var.protect_from_destroy ? 0 : 1
  name                 = var.name
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.force_delete

  encryption_configuration {
    encryption_type = var.kms_key_arn == null ? var.encryption_type : "KMS"
    kms_key         = var.kms_key_arn
  }

  image_scanning_configuration { scan_on_push = var.scan_on_push }
  tags = var.tags
}

########################################
# Unified handles to whichever exists
########################################

locals {
  repo_name = try(
    aws_ecr_repository.protected[0].name,
    aws_ecr_repository.unprotected[0].name
  )
  repo_url = try(
    aws_ecr_repository.protected[0].repository_url,
    aws_ecr_repository.unprotected[0].repository_url
  )
  repo_arn = try(
    aws_ecr_repository.protected[0].arn,
    aws_ecr_repository.unprotected[0].arn
  )
}

########################################
# Lifecycle policies (single resources)
########################################

# Rule 1: Keep last N images (any tag)
resource "aws_ecr_lifecycle_policy" "keep_last_n" {
  count      = var.enable_keep_last_n ? 1 : 0
  repository = local.repo_name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.keep_last_n} images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = var.keep_last_n
      }
      action = { type = "expire" }
    }]
  })
}

# Rule 2: Purge untagged older than X days
resource "aws_ecr_lifecycle_policy" "purge_untagged" {
  count      = var.enable_purge_untagged ? 1 : 0
  repository = local.repo_name

  policy = jsonencode({
    rules = [{
      rulePriority = 2
      description  = "Purge untagged images older than ${var.purge_untagged_days} days"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = var.purge_untagged_days
      }
      action = { type = "expire" }
    }]
  })
}

########################################
# Optional explicit repository policy
########################################

resource "aws_ecr_repository_policy" "this" {
  count      = var.repository_policy_json == null ? 0 : 1
  repository = local.repo_name
  policy     = var.repository_policy_json
}

