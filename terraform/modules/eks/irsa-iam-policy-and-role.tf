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
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:${var.app_namespace}:${var.app_service_account}"
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
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail" #### DUMMY CHANGE ME
        ]
        Resource = "*"
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


