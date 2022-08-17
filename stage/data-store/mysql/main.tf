
    provider "aws" {
      region = "us-east-2"
    }

    

    terraform {
      backend "s3" {
              bucket = "warmup-running-state"
              key    = "stage/data-store/mysql/terraform.tfstate"
              region = "us-east-2"
              dynamodb_table = "warmup-running-locks"
              encrypt = true
      }
    }

    resource "aws_db_instance" "warmup" {
      identifier_prefix = "warmup-up-and-running"
      engine = "mysql"
      allocated_storage = 10
      instance_class = "db.t2.micro"
      db_name = "warmup_database"
      skip_final_snapshot = true
      username = var.db_username
      password = var.db_password
    }


