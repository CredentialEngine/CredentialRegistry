resource "aws_iam_role" "cert_manager_irsa_role" {
  name = "${var.cluster_name}-cert-manager-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:cert-manager:cert-manager"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = var.cluster_name
  }
}

resource "aws_iam_policy" "cert_manager_route53_policy" {
  name        = "${var.cluster_name}-cert-manager-route53-policy"
  description = "Permissions for cert-manager to manage Route53 DNS records"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "route53:GetChange",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets"
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/${var.route53_hosted_zone_id}",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = "route53:ListHostedZonesByName"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cert_manager_route53_attach" {
  role       = aws_iam_role.cert_manager_irsa_role.name
  policy_arn = aws_iam_policy.cert_manager_route53_policy.arn
}


output "cert_manager_irsa_role_arn" {
  description = "IRSA CertManager IAM Role ARN"
  value       = aws_iam_role.cert_manager_irsa_role.arn
}

## IRSA for app

locals {
  # Sandbox intentionally excluded — the sandbox app uses its own dedicated
  # least-privilege role (application_irsa_role_sandbox) so it cannot assume
  # this shared role or reach production S3.
  app_irsa_subjects = [
    "system:serviceaccount:${var.app_namespace}:${var.app_service_account}",
    "system:serviceaccount:${var.app_namespace_prod}:${var.app_service_account_prod}"
  ]
}

resource "aws_iam_role" "application_irsa_role" {
  name = "${var.cluster_name}-application-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = local.app_irsa_subjects,
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = var.cluster_name
  }
}


resource "aws_iam_policy" "application_policy" {
  name        = "${var.cluster_name}-application-policy"
  description = "Permissions for application to interact with AWS services/resources"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ObjectRW",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-graphs/*",
          "arn:aws:s3:::cer-envelope-graphs-staging/*",
          "arn:aws:s3:::cer-envelope-graphs-sandbox/*",
          "arn:aws:s3:::cer-envelope-graphs-sandb/*",
          "arn:aws:s3:::cer-envelope-graphs-prod/*",
          "arn:aws:s3:::cer-envelope-graphs-prod-us-east-1/*",
          "arn:aws:s3:::cer-envelope-downloads/*",
          "arn:aws:s3:::ocn-exports/*",
          "arn:aws:s3:::cer-resources*/*",
          "arn:aws:s3:::cer-db-dumps-prod/*"
        ]
      },
      {
        "Sid" : "DbDumpsGetObject",
        "Effect" : "Allow",
        "Action" : ["s3:GetObject"],
        "Resource" : ["arn:aws:s3:::cer-db-dumps-prod/*"]
      },
      {
        "Sid" : "S3BucketReadMeta",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-graphs",
          "arn:aws:s3:::cer-envelope-graphs-staging",
          "arn:aws:s3:::cer-envelope-graphs-sandbox",
          "arn:aws:s3:::cer-envelope-graphs-sandb",
          "arn:aws:s3:::cer-envelope-graphs-prod",
          "arn:aws:s3:::cer-envelope-graphs-prod-us-east-1",
          "arn:aws:s3:::cer-envelope-downloads",
          "arn:aws:s3:::ocn-exports",
          "arn:aws:s3:::cer-resources*",
          "arn:aws:s3:::cer-db-dumps-prod"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "application_irsa_role_attach" {
  role       = aws_iam_role.application_irsa_role.name
  policy_arn = aws_iam_policy.application_policy.arn
}


output "application_irsa_role_arn" {
  description = "IRSA application IAM Role ARN"
  value       = aws_iam_role.application_irsa_role.arn
}


## Dedicated IRSA role for the sandbox application.
## Isolated from the shared staging/prod application role above so the sandbox
## workload cannot read/write production S3 (envelope-graphs-prod, db-dumps-prod,
## etc.). Scoped to only the buckets the sandbox Registry app actually uses.
resource "aws_iam_role" "application_irsa_role_sandbox" {
  name = "${var.cluster_name}-sandbox-application-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:${var.app_namespace_sandbox}:${var.app_service_account_sandbox}",
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "${var.cluster_name}-sandbox"
  }
}

resource "aws_iam_policy" "application_policy_sandbox" {
  name        = "${var.cluster_name}-sandbox-application-policy"
  description = "Least-privilege S3 permissions for the sandbox Registry application"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ObjectRW",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-downloads/*",
          "arn:aws:s3:::cer-envelope-graphs-sandb/*",
          "arn:aws:s3:::cer-registry-changesets-sandbox/*"
        ]
      },
      {
        "Sid" : "S3BucketReadMeta",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-downloads",
          "arn:aws:s3:::cer-envelope-graphs-sandb",
          "arn:aws:s3:::cer-registry-changesets-sandbox"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "application_irsa_role_sandbox_attach" {
  role       = aws_iam_role.application_irsa_role_sandbox.name
  policy_arn = aws_iam_policy.application_policy_sandbox.arn
}

output "application_irsa_role_sandbox_arn" {
  description = "IRSA sandbox application IAM Role ARN"
  value       = aws_iam_role.application_irsa_role_sandbox.arn
}


## Dedicated IRSA role for the production application.
## Isolated from the shared staging/prod application role above so prod runs on
## a least-privilege role scoped to only the buckets the prod Registry app
## actually uses (verified: downloads, prod envelope-graphs, ocn-exports for the
## ce_registry OCN export, and the prod changeset bucket).
resource "aws_iam_role" "application_irsa_role_prod" {
  name = "${var.cluster_name}-prod-application-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:${var.app_namespace_prod}:${var.app_service_account_prod}",
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Terraform   = "true"
    Environment = "${var.cluster_name}-prod"
  }
}

resource "aws_iam_policy" "application_policy_prod" {
  name        = "${var.cluster_name}-prod-application-policy"
  description = "Least-privilege S3 permissions for the production Registry application"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "S3ObjectRW",
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-downloads/*",
          "arn:aws:s3:::cer-envelope-graphs-prod-us-east-1/*",
          "arn:aws:s3:::ocn-exports/*",
          "arn:aws:s3:::cer-registry-changesets-prod/*"
        ]
      },
      {
        "Sid" : "S3BucketReadMeta",
        "Effect" : "Allow",
        "Action" : [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        "Resource" : [
          "arn:aws:s3:::cer-envelope-downloads",
          "arn:aws:s3:::cer-envelope-graphs-prod-us-east-1",
          "arn:aws:s3:::ocn-exports",
          "arn:aws:s3:::cer-registry-changesets-prod"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "application_irsa_role_prod_attach" {
  role       = aws_iam_role.application_irsa_role_prod.name
  policy_arn = aws_iam_policy.application_policy_prod.arn
}

output "application_irsa_role_prod_arn" {
  description = "IRSA production application IAM Role ARN"
  value       = aws_iam_role.application_irsa_role_prod.arn
}
