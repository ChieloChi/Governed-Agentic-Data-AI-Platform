output "karpenter_controller_role_arn" {
  description = "IAM Role ARN for Karpenter Controller (IRSA)"
  value       = aws_iam_role.karpenter_controller.arn
}

output "karpenter_node_role_name" {
  description = "IAM Role Name for Karpenter Nodes"
  value       = aws_iam_role.karpenter_node.name
}

output "karpenter_queue_name" {
  description = "SQS Queue Name for Karpenter Spot Interruption handling"
  value       = aws_sqs_queue.karpenter_interruption.name
}

