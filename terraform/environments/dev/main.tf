provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# 1. Security Module (KMS Keys for EKS Secrets Envelope & Storage)
module "security" {
  source = "../../modules/security"

  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags
}

# 2. VPC Module (Multi-AZ Networking, Subnets, S3 Endpoint, Karpenter Discovery Tags)
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  cluster_name         = var.cluster_name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = var.tags
}

# 3. EKS Platform Module (EKS 1.30, OIDC Provider, Access Entries, System Spot Nodes)
module "eks" {
  source = "../../modules/eks"

  project_name             = var.project_name
  environment              = var.environment
  cluster_name             = var.cluster_name
  vpc_id                   = module.vpc.vpc_id
  control_plane_subnet_ids = module.vpc.public_subnet_ids
  # In dev with no NAT, system nodes deploy into public subnets with direct internet access
  system_node_subnet_ids = var.enable_nat_gateway ? module.vpc.private_subnet_ids : module.vpc.public_subnet_ids
  kms_key_arn            = module.security.eks_kms_key_arn
  system_instance_types  = ["t3.medium"]
  tags                   = var.tags
}

# 4. Karpenter Autoscaling Module (Just-in-Time EC2 Spot GPU Provisioning)
module "karpenter" {
  source = "../../modules/karpenter"

  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = var.tags
}

# 5. Secrets Module (Encrypted Platform Credentials + External Secrets IRSA Role)
module "secrets" {
  source = "../../modules/secrets"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = module.eks.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  tags              = var.tags
}
