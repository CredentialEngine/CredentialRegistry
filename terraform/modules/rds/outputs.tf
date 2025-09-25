output "db_security_group_id" {
  value = aws_security_group.app_db_security_group_rds.id
}

output "db_endpoint" {
  value = aws_db_instance.application_main_db.endpoint
}
