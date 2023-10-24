provider "aws" {
  region = "us-east-2"
}

module "db_instance" {
  source = "../../../modules/data-storage/mysql"
  db_identifier_prefix = "mysql-dev"
}

terraform {
  backend "s3" {
    bucket = "terraform-state-mgmt-joshprom2000369"
    key = "dev/data-storage/mysql/terraform.tfstate"
    region = "us-east-2"
  }
}