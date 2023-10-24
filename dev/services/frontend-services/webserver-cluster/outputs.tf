# Output public A record of load balancer for quick validation
output "alb_dns_name" {
    value = module.webserver_cluster.alb_dns_name
    description = "DNS RRData (host name) of load balancer"
}

output "alb_sec_group_id" {
  value = module.webserver_cluster.alb_sec_group_id
  description = "ID of security group attached to ALB"
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
  description = "ASG name for environmental reference"
}