output "eks_kms_key_arn" {
  description = "ARN of the KMS Key used for EKS Secrets Envelope Encryption"
  value       = aws_kms_key.eks.arn
}

output "eks_kms_key_id" {
  description = "ID of the KMS Key used for EKS Secrets Envelope Encryption"
  value       = aws_kms_key.eks.key_id
}

output "storage_kms_key_arn" {
  description = "ARN of the KMS Key used for persistent storage, EBS, S3, and logs"
  value       = aws_kms_key.storage.arn
}

output "storage_kms_key_id" {
  description = "ID of the KMS Key used for persistent storage, EBS, S3, and logs"
  value       = aws_kms_key.storage.key_id
}

