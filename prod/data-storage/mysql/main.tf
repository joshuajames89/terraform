provider "aws" {
  region = "us-east-2"
}

module "db_instance" {
  source = "../../../modules/data-storage/mysql"
  db_identifier_prefix = "mysql-prod"
}