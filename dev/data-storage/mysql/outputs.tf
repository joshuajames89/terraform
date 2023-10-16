output "address" {
  value = aws_db_instance.dev_datastore.address
  description = "db connection endpoint"
}

output "port" {
  value = aws_db_instance.dev_datastore.port
  description = "port the db is listening on"
}