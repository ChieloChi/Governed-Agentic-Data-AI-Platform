variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Target deployment environment"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC Provider"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the EKS OIDC Provider"
  type        = string
}

variable "tags" {
  description = "Tags for secrets resources"
  type        = map(string)
  default     = {}
}

