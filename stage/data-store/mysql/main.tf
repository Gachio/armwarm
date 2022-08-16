
    provider "aws" {
      region = "us-east-2"
    }

    resource "aws_db_instance" "warmup" {
      identifier_prefix = "warmup-up-and-running"
      engine = "mysql"
      allocated_storage = 10
      instance_class = "db.t2.micro"
      db_name = "warmup_database"
      username = "admin"

      # How should we set the password?
      password = data.aws_secretsmanager_secret_version.db_password.secret_string
    }

/*
    data "aws_secretsmanager_secret_version" "db_password" {
        secret_id = "mysql-master-password-stage"
    }
*/
