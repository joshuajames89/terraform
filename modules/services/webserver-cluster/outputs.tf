# Output public A record of load balancer for quick validation
output "alb_dns_name" {
    value = aws_lb.webappalb.dns_name
    description = "DNS RRData (host name) of load balancer"
}

output "alb_sec_group_id" {
  value = aws_security_group.alb.id
  description = "ID of security group attached to ALB"
}

output "asg_name" {
  value = aws_autoscaling_group.example.name
  description = "ASG name for environmental reference"
}