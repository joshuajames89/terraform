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

resource "aws_security_group_rule" "allow-dev-ingress" {
  type = "ingress"
  security_group_id = module.webserver_cluster.alb_sec_group_id

  from_port = 55268
  to_port = 55268
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}