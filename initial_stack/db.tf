resource "aws_db_instance" "initial_db" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = false
  final_snapshot_identifier = join("-", ["db-snapshot", formatdate("YYYYMMDDhhmmss", timestamp())])
  publicly_accessible  = false
}

resource "aws_s3_object" "db_dump_file" {
  bucket = aws_s3_bucket.foo_bucket.id

  key    = "mysqlsampledatabase.sql"
  source = "mysqlsampledatabase.sql"

  etag = filemd5("mysqlsampledatabase.sql")
}

output "initial_db_final_snapshot" {
  value = aws_db_instance.initial_db.final_snapshot_identifier
}