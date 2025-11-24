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
  app_irsa_subjects = [
    "system:serviceaccount:${var.app_namespace}:${var.app_service_account}",
    "system:serviceaccount:${var.app_namespace_sandbox}:${var.app_service_account_sandbox}",
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
          "arn:aws:s3:::cer-envelope-graphs-staging/*",
          "arn:aws:s3:::cer-envelope-graphs-sandbox/*",
          "arn:aws:s3:::cer-envelope-graphs-prod/*",
          "arn:aws:s3:::cer-envelope-downloads/*"
        ]
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
          "arn:aws:s3:::cer-envelope-graphs-staging",
          "arn:aws:s3:::cer-envelope-graphs-sandbox",
          "arn:aws:s3:::cer-envelope-graphs-prod",
          "arn:aws:s3:::cer-envelope-downloads"
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
