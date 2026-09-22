
output "name" {
  value = aws_db_instance.main.db_name
}

output "db_master_secret_arn" {
  value = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "db_instance_endpoint" {
  value = aws_db_instance.main.endpoint
}
