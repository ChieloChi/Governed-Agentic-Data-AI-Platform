variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Target deployment environment (dev, prod)"
  type        = string
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

