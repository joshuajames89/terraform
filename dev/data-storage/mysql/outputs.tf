output "address" {
  value = module.db_instance.address
  description = "db connection endpoint"
}

output "port" {
  value = module.db_instance.port
  description = "port the db is listening on"
}