# Dedicated environment node groups: prod, staging, sandbox

# resource "aws_eks_node_group" "ng_prod" {
#   cluster_name    = aws_eks_cluster.eks_cluster.name
#   node_group_name = "${var.cluster_name}-ng-prod"
#   node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
#   subnet_ids      = var.private_subnets

#   ami_type       = "AL2023_x86_64_STANDARD"
#   capacity_type  = "ON_DEMAND"
#   disk_size      = 20
#   instance_types = ["t3.medium"]

#   labels = { env = "prod" }

#   taint {
#     key    = "env"
#     value  = "prod"
#     effect = "NO_SCHEDULE"
#   }

#   scaling_config {
#     desired_size = 2
#     min_size     = 2
#     max_size     = 3
#   }

#   lifecycle { ignore_changes = [scaling_config[0].desired_size] }

#   update_config { max_unavailable = 1 }

#   depends_on = [
#     aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
#     aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
#     aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
#   ]

#   tags = merge(
#     var.common_tags,
#     {
#       "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
#       "k8s.io/cluster-autoscaler/enabled"             = "true"
#     }
#   )
# }

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
    desired_size = 2
    min_size     = 2
    max_size     = 3
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
      Name = "${var.cluster_name}-ng-staging"
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
    desired_size = 1
    min_size     = 1
    max_size     = 3
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
      Name = "${var.cluster_name}-ng-sandbox"
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )
}
