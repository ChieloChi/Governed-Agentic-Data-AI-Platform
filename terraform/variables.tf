variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "ai-infra-eks"
}

variable "system_instance_type" {
  description = "EC2 Instance type for system/platform pods (LiteLLM, Redis, Qdrant)"
  type        = string
  default     = "t3.medium"
}

variable "gpu_instance_type" {
  description = "EC2 Instance type for GPU model inference"
  type        = string
  default     = "g4dn.xlarge"
}

