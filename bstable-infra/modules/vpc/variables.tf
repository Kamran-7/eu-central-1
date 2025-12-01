variable "project" {
  type        = string
  description = "Project name"
  validation {
    condition     = length(var.project) > 0 && length(var.project) <= 20
    error_message = "Project name must be between 1 and 20 characters."
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

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block for the network (e.g., 10.0.0.0/16)"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets to create"
  default     = 2
  validation {
    condition     = var.public_subnet_count >= 2 && var.public_subnet_count <= 6
    error_message = "Public subnet count must be between 2 and 6."
  }
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets to create"
  default     = 3
  validation {
    condition     = var.private_subnet_count >= 1 && var.private_subnet_count <= 6
    error_message = "Private subnet count must be between 1 and 6."
  }
}
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Two private subnets for RDS (leave empty if you don’t want DB subnets)
variable "db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for DB subnets (e.g., [\"10.0.5.0/24\", \"10.0.6.0/24\"])"
  default     = []
}

