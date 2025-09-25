# IAM role and policy for Cluster Autoscaler (IRSA)

# This role allows the Cluster Autoscaler running inside the EKS cluster to
# call the AWS Auto Scaling APIs in order to scale the managed node groups.

resource "aws_iam_role" "cluster_autoscaler_irsa_role" {
  name = "${var.cluster_name}-cluster-autoscaler-irsa-role"

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
            "${replace(aws_iam_openid_connect_provider.oidc_provider.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:cluster-autoscaler"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.cluster_name}-cluster-autoscaler-irsa-role"
    }
  )
}

# IAM policy with the minimal set of permissions required by the Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${var.cluster_name}-cluster-autoscaler-policy"
  description = "Permissions for Cluster Autoscaler to manage Auto Scaling Groups for EKS managed node groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "autoscaling:DescribeScalingActivities",
          "ec2:DescribeLaunchTemplateVersions",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_attach" {
  role       = aws_iam_role.cluster_autoscaler_irsa_role.name
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
}

output "cluster_autoscaler_irsa_role_arn" {
  description = "IRSA IAM Role ARN used by the Cluster Autoscaler service account"
  value       = aws_iam_role.cluster_autoscaler_irsa_role.arn
}
