output "db_security_group_id" {
  value = aws_security_group.app_db_security_group_rds.id
}

output "db_endpoint" {
  value = var.enable_db_instance ? aws_db_instance.application_main_db[0].endpoint : null
}
