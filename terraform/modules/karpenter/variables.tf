variable "cluster_name" {
  description = "Name of the EKS cluster"
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
  description = "Tags for Karpenter resources"
  type        = map(string)
  default     = {}
}

