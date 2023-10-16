# Output public A record of load balancer for quick validation
output "alb_dns_name" {
    value = aws_lb.webappalb.dns_name
    description = "DNS RRData (host name) of load balancer"
}