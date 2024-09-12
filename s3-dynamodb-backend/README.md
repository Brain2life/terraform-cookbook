# Configure Terraform remote state with AWS S3 and DynamoDB for state locking

## Overview

The given template configures AWS S3 backend to store Terraform state and sets AWS DynamoDB for state locking.

The template sets the following configurations:
- Enable S3 bucket versioning
- Enable default server-side encryption with AES256
- Enable S3 bucket logging to monitor the access to the state file
- Enable S3 Object locking to prevent even versioned objects from being deleted before a retention period
- Disable public access to S3 bucket
- Prevent accidental deletion of S3 bucket
- Sets DynamoDB with pay per request billing mode

To configure your your project to use new remote S3 backend add the following code with your values:
```
terraform {
  backend "s3" {
    bucket = "s3-bucket-state"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"

    dynamodb_table = "dynamodb-state-locks"
    encrypt = true
  }
}
```

To migrate to a new backend use the following command:
```bash
terraform init -migrate-state
```

## Adding S3 bucket policies to further restrict access
It's good to explicitly define a bucket policy to further restrict access to the S3 bucket. You can enforce that only specific users or roles can access the bucket. This is left as optional feature.

Example of a bucket policy to restrict access to only the necessary IAM roles:
```
resource "aws_s3_bucket_policy" "terraform_state_policy" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:role/YOUR_ROLE"
        }
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}",
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      },
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.terraform_state.arn}",
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
```

## References:
- [Terraform Docs: S3 backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS S3 object lock](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html)