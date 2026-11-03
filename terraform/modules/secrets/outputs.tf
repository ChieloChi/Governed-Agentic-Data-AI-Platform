output "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.platform_secrets.name
}

output "secret_arn" {
  description = "ARN of the secret in AWS Secrets Manager"
  value       = aws_secretsmanager_secret.platform_secrets.arn
}

output "external_secrets_role_arn" {
  description = "IAM Role ARN for External Secrets Operator (IRSA)"
  value       = aws_iam_role.external_secrets_role.arn
}

