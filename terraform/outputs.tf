output "cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.ai_cluster.name
}

output "cluster_endpoint" {
  description = "EKS Cluster Control Plane endpoint"
  value       = aws_eks_cluster.ai_cluster.endpoint
}

output "configure_kubectl_command" {
  description = "Run this command to configure kubectl context"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.ai_cluster.name}"
}

output "verify_gpu_node_command" {
  description = "Run this command to check if the GPU node registered successfully"
  value       = "kubectl get nodes -l role=gpu-inference -o wide"
}

output "secrets_manager_secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.platform_secrets.name
}

output "external_secrets_role_arn" {
  description = "IAM Role ARN for External Secrets Operator (IRSA)"
  value       = aws_iam_role.external_secrets_role.arn
}
