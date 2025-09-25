# IAM Role and Policy for External Secrets Operator (IRSA)

# This role allows the External Secrets Operator controller running inside the
# EKS cluster to read secret values from AWS Secrets Manager (and, optionally,
# parameters from SSM Parameter Store).  The role is assumed via the EKS
# OIDC provider (IRSA) by the Kubernetes ServiceAccount that the controller
# uses.

resource "aws_iam_role" "external_secrets_irsa_role" {
  name = "${var.cluster_name}-external-secrets-irsa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            # The service account used by the operator is
            #   system:serviceaccount:external-secrets:external-secrets
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:external-secrets:external-secrets"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-external-secrets-irsa-role"
    }
  )
}

# Minimal set of permissions for the operator to read secrets from
# AWS Secrets Manager and (optionally) objects encrypted with customer managed
# KMS keys.  Adjust the resources to restrict access to specific ARNs if
# necessary.

resource "aws_iam_policy" "external_secrets_policy" {
  name        = "${var.cluster_name}-external-secrets-policy"
  description = "Permissions for External Secrets Operator to read AWS Secrets Manager secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecrets"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMGetParametersOptional"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },
      {
        Sid      = "KMSDecryptOptional"
        Effect    = "Allow"
        Action    = ["kms:Decrypt"]
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_secrets_attach" {
  role       = aws_iam_role.external_secrets_irsa_role.name
  policy_arn = aws_iam_policy.external_secrets_policy.arn
}

# Export the role ARN so that it can be referenced in the Kubernetes manifest
# for the External Secrets Operator service account.

output "external_secrets_irsa_role_arn" {
  description = "IRSA IAM Role ARN used by the External Secrets Operator"
  value       = aws_iam_role.external_secrets_irsa_role.arn
}
