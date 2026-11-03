variable "aws_region" {
  description = "AWS Region for Terraform remote state backend"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "ai-platform"
}

variable "environment" {
  description = "Target environment (bootstrap)"
  type        = string
  default     = "bootstrap"
}

variable "tags" {
  description = "Default tags for bootstrap resources"
  type        = map(string)
  default = {
    Project   = "ai-platform"
    ManagedBy = "terraform"
    Layer     = "bootstrap"
  }
}

