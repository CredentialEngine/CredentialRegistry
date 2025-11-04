variable "env" {
  description = "Environment name"
  type        = string
}

# VPC Variables
variable "vpc_cidr" {
  description = "VPC Cidr"
}

variable "public_subnet_cidrs" {
  description = "public_subnet_cidrs"
}

variable "private_subnet_cidrs" {
  description = "private_subnet_cidrs"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
}

variable "db_name_sandbox" {
  type        = string
  description = "Staging DB instance name"
}
variable "db_name_staging" {
  type        = string
  description = "Staging DB instance name"
}
variable "db_name_prod" {
  type        = string
  description = "Production DB instance name"
}

variable "db_username_sandbox" {
  type        = string
  description = "Staging Database master username"
}

variable "db_username_staging" {
  type        = string
  description = "Staging Database master username"
}
variable "db_username_prod" {
  type        = string
  description = "Production Database master username"
}

variable "ssm_db_password_arn" {
  type        = string
  description = "ssm_db_password_arn"
}

variable "image_tag_sandbox" {
  type        = string
  description = "Staging Image tag to deploy from ECR"
}
variable "image_tag_staging" {
  type        = string
  description = "Staging Image tag to deploy from ECR"
}
variable "image_tag_prod" {
  type        = string
  description = "Production Image tag to deploy from ECR"
}
variable "rds_engine_version" {
  type        = string
  description = "rds_engine_version"
}

variable "allocated_storage" {
  type        = number
  description = "RDS Allocated storage"
}

variable "cluster_version" {
  type        = string
  description = "Kubernetes version"
}

variable "priv_ng_max_size" {
  type        = number
  description = "EKS node group max size"
}

variable "priv_ng_min_size" {
  type        = number
  description = "EKS node group min size"
}

variable "priv_ng_des_size" {
  type        = number
  description = "EKS node group desired size"
}

variable "priv_ng_instance_type" {
  type        = string
  description = "EKS node group instance type"
}

# Scaling for environment node groups
variable "ng_staging_min_size" {
  type        = number
  description = "Staging node group min size"
}

variable "ng_staging_desired_size" {
  type        = number
  description = "Staging node group desired size"
}

variable "ng_staging_max_size" {
  type        = number
  description = "Staging node group max size"
}

variable "ng_sandbox_min_size" {
  type        = number
  description = "Sandbox node group min size"
}

variable "ng_sandbox_desired_size" {
  type        = number
  description = "Sandbox node group desired size"
}

variable "ng_sandbox_max_size" {
  type        = number
  description = "Sandbox node group max size"
}

# ---------------------------------------------------------------------------
# Secret values for Laravel application (stored in AWS Secrets Manager)
# ---------------------------------------------------------------------------

variable "db_password_sandbox" {
  type        = string
  description = "Primary database password (sensitive)"
  sensitive   = true
}
variable "db_password_staging" {
  type        = string
  description = "Primary database password (sensitive)"
  sensitive   = true
}

variable "db_password_prod" {
  type        = string
  description = "Primary database password (sensitive)"
  sensitive   = true
}

variable "secret_key_base_sandbox" {
  type        = string
  description = "secret key base (sensitive)"
  sensitive   = true
}

variable "secret_key_base_staging" {
  type        = string
  description = "secret key base (sensitive)"
  sensitive   = true
}
variable "secret_key_base_prod" {
  type        = string
  description = "secret key base (sensitive)"
  sensitive   = true
}

variable "db_host_sandbox" {
  type        = string
  description = "DB host url (sensitive)"
  sensitive   = true
}
variable "db_host_staging" {
  type        = string
  description = "DB host url (sensitive)"
  sensitive   = true
}

variable "db_host_prod" {
  type        = string
  description = "DB host url (sensitive)"
  sensitive   = true
}

variable "redis_url_sandbox" {
  type        = string
  description = "Redis host url (sensitive)"
  sensitive   = true
}
variable "redis_url_staging" {
  type        = string
  description = "Redis host url (sensitive)"
  sensitive   = true
}

variable "redis_url_prod" {
  type        = string
  description = "Redis host url (sensitive)"
  sensitive   = true
}

variable "sidekiq_username_sandbox" {
  type        = string
  description = "Sidekiq UI username (sensitive)"
  sensitive   = true
}

variable "sidekiq_username_staging" {
  type        = string
  description = "Sidekiq UI username (sensitive)"
  sensitive   = true
}

variable "sidekiq_username_prod" {
  type        = string
  description = "Sidekiq UI username (sensitive)"
  sensitive   = true
}

variable "sidekiq_password_sandbox" {
  type        = string
  description = "Sidekiq UI password (sensitive)"
  sensitive   = true
}

variable "sidekiq_password_staging" {
  type        = string
  description = "Sidekiq UI password (sensitive)"
  sensitive   = true
}

variable "sidekiq_password_prod" {
  type        = string
  description = "Sidekiq UI password (sensitive)"
  sensitive   = true
}

variable "route53_hosted_zone_id" {
  description = "route53_hosted_zone_id"
  type        = string
}

variable "app_namespace_sandbox" {
  description = "Staging K8s application namespace"
  type        = string
}

variable "app_namespace_staging" {
  description = "Staging K8s application namespace"
  type        = string
}

variable "app_namespace_prod" {
  description = "Production K8s application namespace"
  type        = string
}
variable "app_service_account_staging" {
  description = "Staging K8s application service account name"
  type        = string
}

# Deprecated: keep for backward compatibility (prefer app_service_account_staging)
variable "app_service_account" {
  description = "[DEPRECATED] Use app_service_account_staging"
  type        = string
  default     = null
}

variable "app_service_account_sandbox" {
  description = "Sandbox K8s application service account name"
  type        = string
  default     = null
}

variable "app_service_account_prod" {
  description = "Production K8s application service account name"
  type        = string
  default     = null
}

variable "ecr_repository_name" {
  description = "Name of the AWS ECR repository"
  type        = string
}

variable "envelope_graphs_bucket_name_staging" {
  description = "S3 bucket name for envelope graphs (staging)"
  type        = string
}

variable "envelope_graphs_bucket_name_sandbox" {
  description = "S3 bucket name for envelope graphs (staging)"
  type        = string
}
