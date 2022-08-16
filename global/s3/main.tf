    provider "aws" {
        region = "us-east-2"
    }

/*
    terraform {
        backend "s3" {
            key = "pailstore/terraform.tfstate"
            dynamodb_table = "warmup-running-locks"
        }
    }
*/

    resource "aws_s3_bucket" "terraform_state" {
    bucket = "warmup-running-state"

    # Prevent accidental deletion of this S3 bucket
    lifecycle {
            prevent_destroy = true
        }
    }

    # Enable versioning so I can see the full revision history of
    # my state files

    resource "aws_s3_bucket_versioning" "enabled" {
        bucket = aws_s3_bucket.terraform_state.id
        versioning_configuration {
            status = "Enabled"
        }
    }

    # Enable server-side encryption by default
    resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
      bucket = aws_s3_bucket.terraform_state.id

        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }

    # Explicity block all public access to the s3 bucket
    resource "aws_s3_bucket_public_access_block" "public_access" {
        bucket = aws_s3_bucket.terraform_state.id
        block_public_acls       = true
        block_public_policy     = true
        ignore_public_acls      = true
        restrict_public_buckets = true
    }
    
    resource "aws_dynamodb_table" "warmup_locks" {
        name = "warmup-locks"
        billing_mode = "PAY_PER_REQUEST"
        hash_key = "LockID" 

        attribute {
            name = "LockID"
            type = "S"
        }   
    }

    output "s3_bucket_arn" {
        value = aws_s3_bucket.terraform_state.arn
        description = "The ARN of the S3 bucket"
    }

    output "dynamodb_table_name" {
        value = aws_dynamodb_table.warmup_locks.name
        description = "The name of the DynamoDB table"
    }

    
