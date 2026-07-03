# Dedicated environment node groups: prod, staging, sandbox

# Production node group (16 GB t3.xlarge). Replaced the original 8 GB t3.large
# ng_prod group via a blue/green migration (issue #1056) so main-app has enough
# memory headroom to publish large frameworks without OOM-killing. Kept named
# _v2 to avoid a resource-address rename (which would force node replacement).
resource "aws_eks_node_group" "ng_prod_v2" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-ng-prod-v2"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = [var.ng_prod_v2_instance_type]

  labels = { env = "production" }

  taint {
    key    = "env"
    value  = "production"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = var.ng_prod_v2_desired_size
    min_size     = var.ng_prod_v2_min_size
    max_size     = var.ng_prod_v2_max_size
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.common_tags,
    {
      Name                                            = "${var.cluster_name}-ng-prod-v2"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )
}

resource "aws_eks_node_group" "ng_staging" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-ng-staging"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]

  labels = { env = "staging" }

  taint {
    key    = "env"
    value  = "staging"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = var.ng_staging_desired_size
    min_size     = var.ng_staging_min_size
    max_size     = var.ng_staging_max_size
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.common_tags,
    {
      Name                                            = "${var.cluster_name}-ng-staging"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )
}

resource "aws_eks_node_group" "ng_sandbox_large" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-ng-sandbox-large"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.large"]

  labels = { env = "sandbox" }

  taint {
    key    = "env"
    value  = "sandbox"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = var.ng_sandbox_large_desired_size
    min_size     = var.ng_sandbox_large_min_size
    max_size     = var.ng_sandbox_large_max_size
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.common_tags,
    {
      Name                                            = "${var.cluster_name}-ng-sandbox-large"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )
}

resource "aws_eks_node_group" "ng_sandbox" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-ng-sandbox"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t3.medium"]

  labels = { env = "sandbox" }

  taint {
    key    = "env"
    value  = "sandbox"
    effect = "NO_SCHEDULE"
  }

  scaling_config {
    desired_size = var.ng_sandbox_desired_size
    min_size     = var.ng_sandbox_min_size
    max_size     = var.ng_sandbox_max_size
  }

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }

  update_config { max_unavailable = 1 }

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = merge(
    var.common_tags,
    {
      Name                                            = "${var.cluster_name}-ng-sandbox"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )
}
