provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"
  cluster_name = "websrv-dev"
  db_remote_state_bucket = "terraform-state-mgmt-joshprom2000369"
  db_remote_state_key = "dev/data-storage/mysql/terraform.tfstate"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}