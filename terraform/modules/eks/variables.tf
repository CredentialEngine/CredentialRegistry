# EKS Cluster Input Variables
variable "cluster_name" {
  description = "Name of the EKS cluster. Also used as a prefix in names of related resources."
  type        = string
  default     = "eksdemo"
}

variable "cluster_service_ipv4_cidr" {
  description = "service ipv4 cidr for the kubernetes cluster"
  type        = string
  default     = null
}

variable "cluster_version" {
  description = "Kubernetes minor version to use for the EKS cluster (for example 1.21)"
  type        = string
  default     = null
}
variable "cluster_endpoint_private_access" {
  description = "Indicates whether or not the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled. When it's set to `false` ensure to have a proper private access with `cluster_endpoint_private_access = true`."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

# VPC Private Subnets
variable "private_subnets" {
  description = "VPC Private Subnets"
  type        = list(string)
}


# Input Variables - AWS IAM OIDC Connect Provider
# EKS OIDC ROOT CA Thumbprint - valid until 2037
variable "eks_oidc_root_ca_thumbprint" {
  type        = string
  description = "Thumbprint of Root CA for EKS OIDC, Valid until 2037"
  default     = "9e99a48a9960b14926bb7f3b02e22da2b0ab7280"
}

variable "route53_hosted_zone_id" {
  description = "route53_hosted_zone_id"
  type        = string
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

variable "ng_prod_min_size" {
  type        = number
  description = "Production node group min size"
}

variable "ng_prod_desired_size" {
  type        = number
  description = "Production node group desired size"
}

variable "ng_prod_max_size" {
  type        = number
  description = "Production node group max size"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "app_namespace" {
  description = "K8s application namespace"
  type        = string
}
variable "app_service_account" {
  description = "K8s application service account name"
  type        = string
}

# Optional: sandbox namespace/service account to include in IRSA trust
variable "app_namespace_sandbox" {
  description = "Sandbox K8s application namespace"
  type        = string
}

variable "app_service_account_sandbox" {
  description = "Sandbox K8s application service account name"
  type        = string
}

variable "app_namespace_prod" {
  description = "Production K8s application namespace"
  type        = string
}

variable "app_service_account_prod" {
  description = "Production K8s application service account name"
  type        = string
}
