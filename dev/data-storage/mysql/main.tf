provider "aws" {
  region = "us-east-2"
}

resource "aws_kms_key" "rds_key" {
  description = "KMS Key for managed master user pw"
  deletion_window_in_days = 10
}

resource "aws_db_instance" "dev_datastore" {
  identifier_prefix = "jp-dev-web-db"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.rds_key.key_id
  username = "admin"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-mgmt-joshprom2000369" # update to use tfvars to create name w/ string concatenation
    key = "dev/data-storage/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}