terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.70"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # NOTE: To enable remote state, run terraform/bootstrap first,
  # then uncomment the backend block below:
  #
  # backend "s3" {
  #   bucket       = "ai-platform-tfstate-us-east-1"
  #   key          = "dev/terraform.tfstate"
  #   region       = "us-east-1"
  #   encrypt      = true
  #   use_lockfile = true
  # }
}

