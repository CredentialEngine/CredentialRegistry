data "aws_ssm_parameter" "ssm_db_password_arn" {
  name = var.ssm_db_password_arn
}

resource "aws_db_subnet_group" "app_db_subnetgroup" {
  name       = "${var.env}-${var.project_name}${var.name_suffix}-db-subnet-group"
  subnet_ids = var.subnet_ids
  tags       = var.common_tags
}

resource "aws_security_group" "app_db_security_group_rds" {
  name        = "${var.env}-${var.project_name}${var.name_suffix}-rds-sg"
  description = var.security_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Temporary wide access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}

resource "aws_db_instance" "application_main_db" {
  identifier                      = "${var.env}-${var.project_name}${var.name_suffix}"
  engine                          = "postgres"
  engine_version                  = var.rds_engine_version
  instance_class                  = var.instance_class
  allocated_storage               = var.allocated_storage
  storage_type                    = "gp3"
  deletion_protection             = var.deletion_protection
  enabled_cloudwatch_logs_exports = var.env == "prod" ? ["audit", "error", "general"] : null
  performance_insights_enabled    = var.env == "prod" ? true : false
  db_name                         = var.db_name
  max_allocated_storage           = 100
  username                        = var.db_username
  password                        = data.aws_ssm_parameter.ssm_db_password_arn.value
  skip_final_snapshot             = var.skip_final_snapshot
  final_snapshot_identifier       = var.skip_final_snapshot ? null : (var.final_snapshot_identifier != null ? var.final_snapshot_identifier : "${var.env}-${var.project_name}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}")
  backup_retention_period         = var.env == "prod" ? 30 : 7 # Enable only for prod
  backup_window                   = "03:00-04:00"
  maintenance_window              = "sun:04:00-sun:05:00"
  db_subnet_group_name            = aws_db_subnet_group.app_db_subnetgroup.name
  vpc_security_group_ids          = [aws_security_group.app_db_security_group_rds.id]
  multi_az                        = var.env == "prod" ? true : false # Enable only for prod
  publicly_accessible             = false
  tags                            = var.common_tags
}
