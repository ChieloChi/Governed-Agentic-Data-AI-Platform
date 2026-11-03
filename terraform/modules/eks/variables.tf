variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Target deployment environment (dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Desired Kubernetes control plane version"
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "VPC ID where EKS is deployed"
  type        = string
}

variable "control_plane_subnet_ids" {
  description = "Subnet IDs for the EKS control plane ENIs"
  type        = list(string)
}

variable "system_node_subnet_ids" {
  description = "Subnet IDs for the system node group"
  type        = list(string)
}

variable "kms_key_arn" {
  description = "KMS Key ARN for EKS Secrets Envelope Encryption (optional)"
  type        = string
  default     = null
}

variable "system_instance_types" {
  description = "Instance types for system node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "Tags for EKS resources"
  type        = map(string)
  default     = {}
}

