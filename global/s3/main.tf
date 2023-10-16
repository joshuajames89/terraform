provider "aws" {
  region = "us-east-2"
}

# Create KMS Key for SSE on S3 bucket object
resource "aws_kms_key" "s3_tfstate_key" {
  description = "Key used to encrypt S3 bucket objects"
  deletion_window_in_days = 10
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-mgmt-joshprom2000369" # Update to use dynamically generated account name based on input variables or tfvar
  object_lock_enabled = true

  # Prevent deletion to protect state indefinitely
  lifecycle {
    prevent_destroy = true
  }
}

# Enable object lock to prevent contention of terraform state files
resource "aws_s3_bucket_object_lock_configuration" "tf_object_lock" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 3
    }
  }
}

# Enable versioning so we can read full version history of state files
resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable SSE on S3 bucket object
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt_tfstate" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_tfstate_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "terraform-state-mgmt-joshprom2000369" # update to use tfvars to create name w/ string concatenation
    key = "global/s3/terraform.tfstate"
    region = "us-east-2"
  }
}