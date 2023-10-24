resource "aws_kms_key" "rds_key" {
  description = "KMS Key for managed master user pw"
  deletion_window_in_days = 10
}

resource "aws_db_instance" "mysql_db" {
  identifier_prefix = "${var.db_identifier_prefix}"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  skip_final_snapshot = true
  manage_master_user_password = true
  master_user_secret_kms_key_id = aws_kms_key.rds_key.key_id
  username = "admin"
}
