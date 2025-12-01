variable "project" {
  type        = string
  description = "Project name"
  validation {
    condition     = length(var.project) > 0
    error_message = "Project name cannot be empty."
  }
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be dev or prod."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  validation {
    condition     = can(regex("^vpc-", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier starting with 'vpc-'."
  }
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB"
  validation {
    condition     = length(var.public_subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets in different AZs."
  }
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
