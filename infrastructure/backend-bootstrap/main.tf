############################################################
# Run this FIRST, in its own folder, with local state.
# It creates the S3 bucket that the main EKS config will
# use as its remote backend.
#
#   cd backend-bootstrap
#   terraform init
#   terraform apply
#
# Note: bucket names must be globally unique across ALL of AWS,
# so the default below appends a random suffix.
############################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  type    = string
  default = "us-west-2"

  validation {
    condition     = contains(["us-east-1", "us-west-2"], var.aws_region)
    error_message = "Sandbox only permits us-east-1 or us-west-2."
  }
}

variable "bucket_prefix" {
  description = "Prefix for the state bucket name (a random suffix is appended for global uniqueness)."
  type        = string
  default     = "eks-sandbox-tfstate"
}


resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.bucket_prefix}-${random_id.suffix.hex}"

  # Prevents accidental deletion of the bucket via terraform destroy
  # while it still holds your live state file.
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "terraform-state"
    Purpose = "eks-sandbox-backend"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled" # lets you recover prior state versions if something corrupts state
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
output "state_bucket_name" {
  value = aws_s3_bucket.tf_state.bucket
}


output "backend_config_block" {
  description = "Copy this into the backend.tf of your main EKS config."
  value       = <<-EOT
  terraform {
    backend "s3" {
      bucket         = "${aws_s3_bucket.tf_state.bucket}"
      key            = "eks-sandbox/terraform.tfstate"
      region         = "${var.aws_region}"
      # DynamoDB-based locking is deprecated. Use S3 lockfile-based
      # locking instead by setting `use_lockfile = true` below.
      use_lockfile   = true
      encrypt        = true
    }
  }
  EOT
}
