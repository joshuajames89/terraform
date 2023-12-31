output "address" {
  value = aws_db_instance.mysql_db.address
  description = "db connection endpoint"
}

output "port" {
  value = aws_db_instance.mysql_db.port
  description = "port the db is listening on"
}