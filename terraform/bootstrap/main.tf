terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# KMS Key for S3 State Bucket Encryption
resource "aws_kms_key" "terraform_state" {
  description             = "KMS Key for ${var.project_name} Terraform remote state S3 bucket"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-state-kms-key"
      Environment = var.environment
    }
  )
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.project_name}-state-kms"
  target_key_id = aws_kms_key.terraform_state.key_id
}

# S3 Bucket for Centralized Remote State Storage
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.project_name}-tfstate-${var.aws_region}"
  force_destroy = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-tfstate"
      Environment = var.environment
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Versioning for State History & Recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-Side Encryption with Customer Managed Key
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.terraform_state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Block all Public Access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce TLS 1.2+ Requests Only
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      }
    ]
  })
}

