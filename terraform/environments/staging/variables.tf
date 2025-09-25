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

variable "db_name" {
  type        = string
  description = "DB instance name"
}

variable "db_username" {
  type        = string
  description = "Database master username"
}

variable "ssm_db_password_arn" {
  type        = string
  description = "ssm_db_password_arn"
}

variable "image_tag" {
  type        = string
  description = "Image tag to deploy from ECR"

}

variable "rds_engine_version" {
  type        = string
  description = "rds_engine_version"
}

variable "cdn_acm_certificate_arn" {
  type        = string
  description = "CloudFront acm_certificate_arn"
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

# ---------------------------------------------------------------------------
# Secret values for Laravel application (stored in AWS Secrets Manager)
# ---------------------------------------------------------------------------


variable "db_password" {
  type        = string
  description = "Primary database password (sensitive)"
  sensitive   = true
}

variable "route53_hosted_zone_id" {
  description = "route53_hosted_zone_id"
  type        = string
}

variable "app_namespace" {
  description = "K8s application namespace"
  type        = string
}

variable "app_service_account" {
  description = "K8s application service account name"
  type        = string
}

