output "s3_bucket_id" {
  description = "The ID/Name of the centralized Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "The ARN of the centralized Terraform state S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "kms_key_arn" {
  description = "The ARN of the Customer Managed KMS Key encrypting the state bucket"
  value       = aws_kms_key.terraform_state.arn
}

output "backend_config_template" {
  description = "Backend configuration template to paste into environments"
  value       = <<-EOT
    backend "s3" {
      bucket       = "${aws_s3_bucket.terraform_state.id}"
      key          = "<env>/terraform.tfstate"
      region       = "${var.aws_region}"
      encrypt      = true
      use_lockfile = true
    }
  EOT
}

