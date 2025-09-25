locals {
  project_name = "ce-registry"
  common_tags = {
    "project"     = local.project_name
    "environment" = var.env
  }
}


module "vpc" {
  source               = "../../modules/vpc"
  project_name         = local.project_name
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
  common_tags          = local.common_tags
}

module "rds" {
  source                     = "../../modules/rds"
  project_name               = local.project_name
  security_group_description = "Allow inbound traffic from bastion"
  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = var.vpc_cidr
  subnet_ids                 = module.vpc.public_subnet_ids
  db_name                    = var.db_name
  db_username                = var.db_username
  instance_class             = var.instance_class
  common_tags                = local.common_tags
  ssm_db_password_arn        = var.ssm_db_password_arn
  rds_engine_version         = var.rds_engine_version
  allocated_storage          = var.allocated_storage
}

module "ecr" {
  source       = "../../modules/ecr"
  project_name = local.project_name
  env          = var.env
}


output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "cluster_autoscaler_irsa_role_arn" {
  description = "IAM role ARN that the Cluster Autoscaler service account should assume via IRSA"
  value       = module.eks.cluster_autoscaler_irsa_role_arn
}


module "eks" {
  source                 = "../../modules/eks"
  environment            = var.env
  cluster_name           = "${local.project_name}-${var.env}"
  cluster_version        = var.cluster_version
  private_subnets        = module.vpc.private_subnet_ids
  common_tags            = local.common_tags
  priv_ng_max_size       = var.priv_ng_max_size
  priv_ng_min_size       = var.priv_ng_min_size
  priv_ng_des_size       = var.priv_ng_des_size
  priv_ng_instance_type  = var.priv_ng_instance_type
  route53_hosted_zone_id = var.route53_hosted_zone_id ## For IRSA role and cert-manager issuance
  app_namespace          = var.app_namespace
  app_service_account    = var.app_service_account
}

# ----------------------------------------------------------------------------
# AWS Secrets Manager secret consumed by the Laravel application via External
# Secrets Operator.  Real values are passed in via TFVARS to avoid committing
# secrets to the repository.
# ----------------------------------------------------------------------------

# module "laravel_application_secret" {
#   source = "../../modules/secrets"

#   secret_name = "laravel-secrets-${var.env}"
#   description = "Laravel application secrets for the ${var.env} environment"

#   secret_values = {
#     DB_PASSWORD                 = var.db_password
#     TRACKER_DB_PASSWORD         = var.tracker_db_password
#     GOOGLE_CLIENT_ID            = var.google_client_id
#     GOOGLE_CLIENT_SECRET        = var.google_client_secret
#     GOOGLE_RECAPTCHA_SECRET_KEY = var.google_recaptcha_secret_key
#     GOOGLE_RECAPTCHA_SITE_KEY   = var.google_recaptcha_site_key
#     HEALTH_CHECK_AUTH_TOKEN     = var.healthcheck_token
#     APP_KEY                     = var.app_key
#   }

#   tags = local.common_tags
# }
