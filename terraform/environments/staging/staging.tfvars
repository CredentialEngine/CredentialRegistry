public_subnet_cidrs            = ["10.19.1.0/24", "10.19.2.0/24"]
private_subnet_cidrs           = ["10.19.3.0/24", "10.19.4.0/24"]
azs                            = ["us-east-1a", "us-east-1b"]
vpc_cidr                       = "10.19.0.0/16"
env                            = "staging"
instance_class                 = "db.t4g.medium" ## DB instance
db_name                        = ???
ssm_db_password_arn            = "arn:aws:ssm:us-east-1:996810415034:parameter/ce-registry/dev/rds_db_password"
image_tag                      = "latest"
rds_engine_version             = "17.5"
allocated_storage              = 40
cluster_version                = 1.33
db_username                    = "admin"
priv_ng_max_size               = 10
priv_ng_min_size               = 1
priv_ng_des_size               = 4 ## this is irrelevant since the cluster uses the autoscaler to determine the appropriate value for it
priv_ng_instance_type          = "t3.large"
route53_hosted_zone_id         = "Z1N75467P1FUL5"

# ---------------------------------------------------------------------------
# Sensitive values for the Laravel application secret. Provide real values via
# secure means (e.g. CI secrets, SSM Parameter Store) before running
# `terraform apply`.
# ---------------------------------------------------------------------------

db_password                     = "CHANGEME-db-pass"
app_namespace                   = "credreg"
app_service_account             = "ce_staging_sa"
