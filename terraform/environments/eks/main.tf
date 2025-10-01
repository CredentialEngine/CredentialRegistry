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

## Staging RDS instance
module "rds-staging" {
  source                     = "../../modules/rds"
  project_name               = local.project_name
  security_group_description = "Allow inbound traffic from bastion"
  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = var.vpc_cidr
  subnet_ids                 = module.vpc.public_subnet_ids
  db_name                    = var.db_name_staging
  db_username                = var.db_username_staging
  instance_class             = var.instance_class
  common_tags                = local.common_tags
  ssm_db_password_arn        = var.ssm_db_password_arn
  rds_engine_version         = var.rds_engine_version
  allocated_storage          = var.allocated_storage
  # Allow destroying without snapshot for staging
  skip_final_snapshot = true
  deletion_protection = false
  name_suffix         = "-staging"
}

## Production RDS instance
module "rds-production" {
  source                     = "../../modules/rds"
  project_name               = local.project_name
  security_group_description = "Allow inbound traffic from bastion"
  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = var.vpc_cidr
  subnet_ids                 = module.vpc.public_subnet_ids
  db_name                    = var.db_name_prod
  db_username                = var.db_username_prod
  instance_class             = var.instance_class
  common_tags                = local.common_tags
  ssm_db_password_arn        = var.ssm_db_password_arn
  rds_engine_version         = var.rds_engine_version
  allocated_storage          = var.allocated_storage
  # Leave production safer by default; override if needed during teardown
  skip_final_snapshot = false
  deletion_protection = true
  name_suffix         = "-prod"
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
  app_namespace          = var.app_namespace_staging
  app_service_account    = var.app_service_account
}

# ----------------------------------------------------------------------------
# AWS Secrets Manager secret consumed by the Laravel application via External
# Secrets Operator.  Real values are passed in via TFVARS to avoid committing
# secrets to the repository.
# ----------------------------------------------------------------------------

module "application_secret" {
  source = "../../modules/secrets"

  secret_name = "credreg-secrets-${var.env}-staging"
  description = "credreg application secrets for the ${var.env} staging environment"

  secret_values = {
    DB_PASSWORD = var.db_password
  }

  tags = local.common_tags
}

module "application_secret_prod" {
  source = "../../modules/secrets"

  secret_name = "credreg-secrets-${var.env}-production"
  description = "credreg application secrets for the ${var.env} production environment"

  secret_values = {
    DB_PASSWORD = var.db_password
  }

  tags = local.common_tags
}
