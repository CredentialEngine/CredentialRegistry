variable "env" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "vpc_cidr" {
  type        = string
  description = "vpc_cidr"
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for RDS"
  type        = list(string)
}

variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t4g.micro"
}

variable "allocated_storage" {
  description = "Storage size in GB"
  type        = number
  default     = 20
}

# variable "ecs_security_group_id" {
#   type        = string
#   description = "ecs_security_group_id"
# }

variable "common_tags" {
  type = map(string)
  default = {
    "name" = "default value"
  }
}

variable "ssm_db_password_arn" {
  type        = string
  description = "ssm_db_password_arn"
}

variable "rds_engine_version" {
  type        = string
  description = "rds_engine_version"
}

variable "security_group_description" {
  type = string
  description = "security_group_description"
}