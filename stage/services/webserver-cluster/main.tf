    data "terraform_remote_state" "db" {
        backend = "s3"

        config = {
            bucket = "warmup-running-state"
            key = "stage/data-store/mysql/terraform.tfstate"
            region = "us-east-2"
        }
    }
    
    terraform {
        backend "s3" {
            key = "stage/services/webserver-cluster/terraform.tfstate"
            dynamodb_table = "warmup-running-locks"
        }
    }