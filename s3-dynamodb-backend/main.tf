provider "aws" {
  region = "us-east-1"
}

# Create S3 bucket for terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "s3-bucket-state"
  object_lock_enabled = true

  # Prevent accidental deletion of this S3 bucket. Set value to 'true'
  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = "TerraformStateBucket"
    Environment = "Dev"
  }
}

# Enable S3 bucket versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable logging for the S3 bucket to monitor and track access to your Terraform state
resource "aws_s3_bucket_logging" "terraform_state_logging" {
  bucket        = aws_s3_bucket.terraform_state.id
  target_bucket = "s3-bucket-state"
  target_prefix = "log/"
}

# Disable public access to S3 bucket
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable S3 Object Lock to prevent even versioned objects from being deleted before a retention period
resource "aws_s3_bucket_object_lock_configuration" "lock_config" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}

# Create DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "dynamodb-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "TerraformStateLocks"
    Environment = "Dev"
  }
}