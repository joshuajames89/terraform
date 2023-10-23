provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"
  cluster_name = "websrv-prod"
  db_remote_state_bucket = "terraform-state-mgmt-joshprom2000369"
  db_remote_state_key = "prod/data-storage/mysql/terraform.tfstate"

  instance_type = "m1.large"
  min_size = 2
  max_size = 10
}

resource "aws_autoscaling_schedule" "scale_up_at_peak" {
  scheduled_action_name = "scale-up-at-peak"
  min_size = 2
  max_size = 10
  desired_capacity = 10
  recurrence = "0 8 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}

resource "aws_autoscaling_schedule" "scale_down_at_eob" {
  scheduled_action_name = "scale-down-at-eob"
  min_size = 2
  max_size = 10
  desired_capacity = 2
  recurrence = "0 16 * * *"

  autoscaling_group_name = module.webserver_cluster.asg_name
}