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
  type        = string
  description = "security_group_description"
}
variable "skip_final_snapshot" {
  description = "Whether to skip taking a final snapshot on DB instance deletion"
  type        = bool
  # Preserve prior behavior: skip for staging, otherwise take snapshot
  default     = false
}

variable "final_snapshot_identifier" {
  description = "Identifier for the final snapshot when deleting the DB instance (required if skip_final_snapshot is false)"
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Enable deletion protection on the DB instance"
  type        = bool
  default     = true
}

variable "name_suffix" {
  description = "Optional suffix to append to named resources (SG, subnet group, identifier) to allow multiple instances in same env"
  type        = string
  default     = ""
}

# When false, this module will not create or manage the DB instance itself.
# It will still create and manage the subnet group and security group.
variable "enable_db_instance" {
  description = "Whether to create/manage the RDS DB instance in this module"
  type        = bool
  default     = true
}
