variable "project" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment (dev, prod)"
}

variable "image_retention_count" {
  type        = number
  description = "Number of images to retain"
  default     = 10
}

variable "name" {
  description = "Full ECR repository name (e.g., bstable-backend)."
  type        = string
}

variable "image_tag_mutability" {
  description = "MUTABLE for dev, IMMUTABLE for prod."
  type        = string
  default     = "MUTABLE"
}

variable "force_delete" {
  description = "Allow repo deletion even if images exist (use true in dev)."
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "AES256 or KMS (ignored if kms_key_arn is provided)."
  type        = string
  default     = "AES256"
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN. If set, encryption_type becomes KMS."
  type        = string
  default     = null
}

variable "scan_on_push" {
  description = "Enable vulnerability scan on push."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the repository."
  type        = map(string)
  default     = {}
}

# ---- Optional lifecycle cleanup toggles ----
variable "enable_keep_last_n" {
  description = "Enable rule to keep only the last N images."
  type        = bool
  default     = true
}

variable "keep_last_n" {
  description = "How many recent images to keep (any tag)."
  type        = number
  default     = 20
}

variable "enable_purge_untagged" {
  description = "Enable rule to purge untagged images older than X days."
  type        = bool
  default     = true
}

variable "purge_untagged_days" {
  description = "Days after which untagged images are purged."
  type        = number
  default     = 7
}

# ---- Optional safety for prod ----
variable "protect_from_destroy" {
  description = "Protect repo from terraform destroy (true in prod)."
  type        = bool
  default     = false
}

# ---- Optional explicit repo policy (cross-account CI/CD etc.) ----
variable "repository_policy_json" {
  description = "Optional IAM policy JSON string for this repository."
  type        = string
  default     = null
}
