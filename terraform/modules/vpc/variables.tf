variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "environment" {
  description = "Target environment (dev, prod)"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name for subnet discovery tags"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to provision NAT Gateways for private subnet outbound internet"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "If true, provision a single shared NAT Gateway across all AZs (cost savings)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to attach to VPC resources"
  type        = map(string)
  default     = {}
}

