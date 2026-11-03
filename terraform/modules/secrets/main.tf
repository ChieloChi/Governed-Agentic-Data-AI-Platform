# 1. Random passwords generated on-the-fly for database and API keys
resource "random_password" "postgres_password" {
  length  = 24
  special = false
}

resource "random_password" "litellm_master_key" {
  length  = 32
  special = false
}

resource "random_password" "cube_api_secret" {
  length  = 32
  special = false
}

# 2. AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "platform_secrets" {
  name                    = "${var.project_name}-${var.environment}/platform-credentials"
  description             = "Zero-trust encrypted credentials for ${var.project_name} (${var.environment})"
  recovery_window_in_days = 0 # Immediate deletion upon terraform destroy

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "platform_secrets_val" {
  secret_id = aws_secretsmanager_secret.platform_secrets.id

  secret_string = jsonencode({
    postgres-password   = random_password.postgres_password.result
    litellm-master-key  = "sk-${random_password.litellm_master_key.result}"
    cube-api-secret     = random_password.cube_api_secret.result
    minio-root-user     = "admin"
    minio-root-password = random_password.postgres_password.result
  })
}

# 3. IAM Role for External Secrets Operator (IRSA)
resource "aws_iam_role" "external_secrets_role" {
  name = "${var.cluster_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = var.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa"
          "${replace(var.oidc_provider_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

# 4. Scoped IAM Policy: Read ONLY the platform secret
resource "aws_iam_policy" "secrets_manager_read" {
  name        = "${var.cluster_name}-secretsmanager-read"
  description = "Allows External Secrets Operator to read platform credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadPlatformSecrets"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = aws_secretsmanager_secret.platform_secrets.arn
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  policy_arn = aws_iam_policy.secrets_manager_read.arn
  role       = aws_iam_role.external_secrets_role.name
}

