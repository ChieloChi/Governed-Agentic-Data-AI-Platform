# Fetch EKS OIDC TLS Certificate for IAM OIDC Identity Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.ai_cluster.identity[0].oidc[0].issuer
}

# EKS OIDC Provider (Enables IAM Roles for Service Accounts - IRSA)
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.ai_cluster.identity[0].oidc[0].issuer

  tags = {
    Name = "${var.cluster_name}-oidc-provider"
  }
}

# IAM Policy: Read permissions on the centralized platform secret
resource "aws_iam_policy" "secrets_read_policy" {
  name        = "${var.cluster_name}-secrets-read-policy"
  description = "Allows External Secrets Operator in EKS to read AI platform credentials"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.platform_secrets.arn
      }
    ]
  })
}

# IAM Role with WebIdentity trust policy for External Secrets ServiceAccount
resource "aws_iam_role" "external_secrets_role" {
  name = "${var.cluster_name}-external-secrets-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_eks_cluster.ai_cluster.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets-sa",
            "${replace(aws_eks_cluster.ai_cluster.identity[0].oidc[0].issuer, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Role = "IRSA-ExternalSecrets"
  }
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "attach_secrets_policy" {
  policy_arn = aws_iam_policy.secrets_read_policy.arn
  role       = aws_iam_role.external_secrets_role.name
}
