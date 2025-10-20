# Create AWS EKS Node Group - Private

resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "${var.cluster_name}-eks-ng-private"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = [var.priv_ng_instance_type]

  scaling_config {
    desired_size = var.priv_ng_des_size
    min_size     = var.priv_ng_min_size
    max_size     = var.priv_ng_max_size
  }

  ###########################################################################
  # Cluster Autoscaler manages the NodeGroup desired size at runtime.  Once
  # the autoscaler is active, Terraform should no longer try to revert the
  # value it changes.  The lifecycle rule below keeps Terraform from
  # detecting drift on `scaling_config[0].desired_size` while still allowing
  # us to set an initial size during first provisioning.
  ###########################################################################
  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  # Desired max percentage of unavailable worker nodes during node group update.
  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly,
  ]
  tags = merge(
    var.common_tags,
    {
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned",
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

}

