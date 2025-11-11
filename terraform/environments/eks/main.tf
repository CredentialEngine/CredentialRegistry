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
  enable_db_instance         = false
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

module "rds-sandbox" {
  source                     = "../../modules/rds"
  enable_db_instance         = false
  project_name               = local.project_name
  security_group_description = "Allow inbound traffic from bastion"
  env                        = var.env
  vpc_id                     = module.vpc.vpc_id
  vpc_cidr                   = var.vpc_cidr
  subnet_ids                 = module.vpc.public_subnet_ids
  db_name                    = var.db_name_sandbox
  db_username                = var.db_username_sandbox
  instance_class             = var.instance_class
  common_tags                = local.common_tags
  ssm_db_password_arn        = var.ssm_db_password_arn
  rds_engine_version         = var.rds_engine_version
  allocated_storage          = var.allocated_storage
  # Allow destroying without snapshot for sandbox
  skip_final_snapshot = true
  deletion_protection = false
  name_suffix         = "-sandbox"
}
## Production RDS instance
# module "rds-production" {
#   source                     = "../../modules/rds"
#   project_name               = local.project_name
#   security_group_description = "Allow inbound traffic from bastion"
#   env                        = var.env
#   vpc_id                     = module.vpc.vpc_id
#   vpc_cidr                   = var.vpc_cidr
#   subnet_ids                 = module.vpc.public_subnet_ids
#   db_name                    = var.db_name_prod
#   db_username                = var.db_username_prod
#   instance_class             = var.instance_class
#   common_tags                = local.common_tags
#   ssm_db_password_arn        = var.ssm_db_password_arn
#   rds_engine_version         = var.rds_engine_version
#   allocated_storage          = var.allocated_storage
#   # Leave production safer by default; override if needed during teardown
#   skip_final_snapshot = false
#   deletion_protection = true
#   name_suffix         = "-prod"
# }

module "ecr" {
  source       = "../../modules/ecr"
  project_name = var.ecr_repository_name
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
  source                      = "../../modules/eks"
  environment                 = var.env
  cluster_name                = "${local.project_name}-${var.env}"
  cluster_version             = var.cluster_version
  private_subnets             = module.vpc.private_subnet_ids
  common_tags                 = local.common_tags
  priv_ng_max_size            = var.priv_ng_max_size
  priv_ng_min_size            = var.priv_ng_min_size
  priv_ng_des_size            = var.priv_ng_des_size
  priv_ng_instance_type       = var.priv_ng_instance_type
  route53_hosted_zone_id      = var.route53_hosted_zone_id ## For IRSA role and cert-manager issuance
  app_namespace               = var.app_namespace_staging
  app_service_account         = coalesce(var.app_service_account_staging, var.app_service_account)
  app_namespace_sandbox       = var.app_namespace_sandbox
  app_service_account_sandbox = var.app_service_account_sandbox
  app_namespace_prod          = var.app_namespace_prod
  app_service_account_prod    = var.app_service_account_prod
  # Env node group scaling
  ng_staging_min_size     = var.ng_staging_min_size
  ng_staging_desired_size = var.ng_staging_desired_size
  ng_staging_max_size     = var.ng_staging_max_size
  ng_sandbox_min_size     = var.ng_sandbox_min_size
  ng_sandbox_desired_size = var.ng_sandbox_desired_size
  ng_sandbox_max_size     = var.ng_sandbox_max_size
  ng_prod_min_size        = var.ng_prod_min_size
  ng_prod_desired_size    = var.ng_prod_desired_size
  ng_prod_max_size        = var.ng_prod_max_size
}

module "application_secret" {
  source = "../../modules/secrets"

  secret_name = "credreg-secrets-${var.env}-staging"
  description = "credreg application secrets for the ${var.env} staging environment"

  secret_values = {
    POSTGRESQL_PASSWORD = var.db_password_staging
    SECRET_KEY_BASE     = var.secret_key_base_staging
    POSTGRESQL_ADDRESS  = var.db_host_staging
    REDIS_URL           = var.redis_url_staging
    SIDEKIQ_USERNAME    = var.sidekiq_username_staging
    SIDEKIQ_PASSWORD    = var.sidekiq_password_staging
  }

  tags = local.common_tags
}

module "application_secret_sandbox" {
  source = "../../modules/secrets"

  secret_name = "credreg-secrets-${var.env}-sandbox"
  description = "credreg application secrets for the ${var.env} sandbox environment"

  secret_values = {
    POSTGRESQL_PASSWORD = var.db_password_sandbox
    SECRET_KEY_BASE     = var.secret_key_base_sandbox
    POSTGRESQL_ADDRESS  = var.db_host_sandbox
    REDIS_URL           = var.redis_url_sandbox
    SIDEKIQ_USERNAME    = var.sidekiq_username_sandbox
    SIDEKIQ_PASSWORD    = var.sidekiq_password_sandbox
  }

  tags = local.common_tags
}

module "application_secret_prod" {
  source = "../../modules/secrets"

  secret_name = "credreg-secrets-${var.env}-production"
  description = "credreg application secrets for the ${var.env} production environment"

  secret_values = {
    POSTGRESQL_PASSWORD = var.db_password_prod
    SECRET_KEY_BASE     = var.secret_key_base_prod
    POSTGRESQL_ADDRESS  = var.db_host_prod
    REDIS_URL           = var.redis_url_prod
    SIDEKIQ_USERNAME    = var.sidekiq_username_prod
    SIDEKIQ_PASSWORD    = var.sidekiq_password_prod
  }

  tags = local.common_tags
}

## Staging S3: Envelope Graphs (module)
module "envelope_graphs_s3_staging" {
  source      = "../../modules/envelope_graphs_s3"
  bucket_name = var.envelope_graphs_bucket_name_staging
  environment = "staging"
  common_tags = local.common_tags
}

output "cer_envelope_graphs_bucket_name" {
  value       = module.envelope_graphs_s3_staging.bucket_name
  description = "Staging S3 bucket name for envelope graphs"
}

## Sandbox S3: Envelope Graphs (module)
module "envelope_graphs_s3_sandbox" {
  source      = "../../modules/envelope_graphs_s3"
  bucket_name = var.envelope_graphs_bucket_name_sandbox
  environment = "sandbox"
  common_tags = local.common_tags
}

output "cer_envelope_graphs_bucket_name_sandbox" {
  value       = module.envelope_graphs_s3_sandbox.bucket_name
  description = "Sandbox S3 bucket name for envelope graphs"
}

## Production S3: Envelope Graphs (module)
module "envelope_graphs_s3_prod" {
  source      = "../../modules/envelope_graphs_s3"
  bucket_name = var.envelope_graphs_bucket_name_prod
  environment = "production"
  common_tags = local.common_tags
}

output "cer_envelope_graphs_bucket_name_prod" {
  value       = module.envelope_graphs_s3_prod.bucket_name
  description = "Production S3 bucket name for envelope graphs"
}
