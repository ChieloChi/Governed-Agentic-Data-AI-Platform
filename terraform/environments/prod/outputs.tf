output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster Control Plane endpoint"
  value       = module.eks.cluster_endpoint
}

output "configure_kubectl_command" {
  description = "Command to configure local kubectl context"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "karpenter_controller_role_arn" {
  description = "IAM Role ARN for Karpenter Controller (IRSA)"
  value       = module.karpenter.karpenter_controller_role_arn
}

output "karpenter_node_role_name" {
  description = "IAM Role Name for Karpenter Nodes"
  value       = module.karpenter.karpenter_node_role_name
}

output "karpenter_queue_name" {
  description = "SQS Queue Name for Karpenter Spot Interruption handling"
  value       = module.karpenter.karpenter_queue_name
}

output "secrets_manager_secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = module.secrets.secret_name
}

output "external_secrets_role_arn" {
  description = "IAM Role ARN for External Secrets Operator (IRSA)"
  value       = module.secrets.external_secrets_role_arn
}

