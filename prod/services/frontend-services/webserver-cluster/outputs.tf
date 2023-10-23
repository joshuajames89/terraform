output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
  description = "DNS RRData (host name) of load balancer"
}
