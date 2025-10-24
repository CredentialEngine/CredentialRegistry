public_subnet_cidrs  = ["10.19.1.0/24", "10.19.2.0/24"]
private_subnet_cidrs = ["10.19.3.0/24", "10.19.4.0/24"]
azs                  = ["us-east-1a", "us-east-1b"]
vpc_cidr             = "10.19.0.0/16"
env                  = "eks"
instance_class       = "db.t4g.medium" ## DB instance
db_name_sandbox      = "ceregistrysandbox"
db_name_staging      = "ceregistrystaging"
db_name_prod         = "ceregistryprod"

ssm_db_password_arn = "arn:aws:ssm:us-east-1:996810415034:parameter/ce-registry/rds/rds_db_password"
image_tag_prod      = "production"
image_tag_staging   = "staging"
image_tag_sandbox   = "sandbox"

rds_engine_version = "17.5"
allocated_storage  = 40
cluster_version    = 1.33

db_username_sandbox = "ceregistrysandbox"
db_username_staging = "ceregistrystaging"
db_username_prod    = "ceregistryprod"

priv_ng_max_size       = 10
priv_ng_min_size       = 0
priv_ng_des_size       = 2 ## this is irrelevant since the cluster uses the autoscaler to determine the appropriate value for it
priv_ng_instance_type  = "t3.large"
route53_hosted_zone_id = "Z1N75467P1FUL5"

ecr_repository_name = "registry"
# ---------------------------------------------------------------------------
# Sensitive values for the Laravel application secret. Provide real values via
# secure means (e.g. CI secrets, SSM Parameter Store) before running
# `terraform apply`.
# ---------------------------------------------------------------------------

db_password_staging      = "CHANGEME-db-pass"
secret_key_base_staging  = "CHANGEME"
db_host_staging          = "CHANGEME"
redis_url_staging        = "CHANGEME"
sidekiq_username_staging = "CHANGEME"
sidekiq_password_staging = "CHANGEME"

db_password_sandbox      = "CHANGEME-db-pass"
secret_key_base_sandbox  = "CHANGEME"
db_host_sandbox          = "CHANGEME"
redis_url_sandbox        = "CHANGEME"
sidekiq_username_sandbox = "CHANGEME"
sidekiq_password_sandbox = "CHANGEME"

db_password_prod      = "CHANGEME-db-pass"
secret_key_base_prod  = "CHANGEME"
db_host_prod          = "CHANGEME"
redis_url_prod        = "CHANGEME"
sidekiq_username_prod = "CHANGEME"
sidekiq_password_prod = "CHANGEME"

app_namespace_sandbox = "credreg-sandbox"
app_namespace_staging = "credreg-staging"
app_namespace_prod    = "credreg-prod"
app_service_account   = "ce_staging_sa"

# Staging S3 bucket for envelope graphs
envelope_graphs_bucket_name_staging = "cer-envelope-graphs-staging"
envelope_graphs_bucket_name_sandbox = "cer-envelope-graphs-sandbox"
