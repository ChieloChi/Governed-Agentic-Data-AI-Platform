# 1. LiteLLM Master Key
resource "random_password" "litellm_master_key" {
  length  = 32
  special = false
}

# 2. PostgreSQL Analytics Datastore Password
resource "random_password" "postgres_password" {
  length  = 24
  special = false
}

# 3. Cube.js Semantic Layer API Secret
resource "random_password" "cube_api_secret" {
  length  = 32
  special = false
}

# Centralized AWS Secrets Manager Secret container
resource "aws_secretsmanager_secret" "platform_secrets" {
  name                    = "${var.cluster_name}/platform-credentials"
  description             = "Zero-trust credentials for AI Platform (LiteLLM, Postgres, Cube.js)"
  recovery_window_in_days = 0 # Ensures instant deletion upon terraform destroy (Zero lingering costs!)

  tags = {
    Component = "AI-Platform-Security"
    ManagedBy = "Terraform"
  }
}

# Secret Version containing all generated keys
resource "aws_secretsmanager_secret_version" "platform_secrets_val" {
  secret_id = aws_secretsmanager_secret.platform_secrets.id
  secret_string = jsonencode({
    litellm_master_key = "sk-admin-${random_password.litellm_master_key.result}"
    postgres_password  = random_password.postgres_password.result
    cube_api_secret    = random_password.cube_api_secret.result
  })
}
