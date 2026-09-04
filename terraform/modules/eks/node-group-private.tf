# Create AWS EKS Node Group - Private

# Launch template for the private node group. Sole purpose: raise kubelet max-pods
# to 110 (via nodeadm) so small instances (t3.medium) aren't capped by the VPC CNI
# ENI IP limit (17). Requires prefix delegation (ENABLE_PREFIX_DELEGATION=true on the
# aws-node DaemonSet), which is set on the cluster. AMI is intentionally omitted so
# EKS keeps managing the AL2023 image and merges its bootstrap with the override.
# Disk sizing moves here because a launch template is attached.
resource "aws_launch_template" "eks_ng_private" {
  name_prefix = "${var.cluster_name}-eks-ng-private-"

  vpc_security_group_ids = [aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  user_data = base64encode(file("${path.module}/private-node-userdata.mime"))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.common_tags, { Name = "${var.cluster_name}-eks-ng-private" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "eks_ng_private" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  # name_prefix (not a fixed name) so create_before_destroy can stand up the
  # replacement node group before the old one is destroyed (see lifecycle below).
  node_group_name_prefix = "${var.cluster_name}-eks-ng-private-"
  node_role_arn          = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids             = var.private_subnets

  ami_type       = "AL2023_x86_64_STANDARD"
  capacity_type  = "ON_DEMAND"
  instance_types = [var.priv_ng_instance_type]

  # disk sizing lives in the launch template (required when a custom LT is attached)
  launch_template {
    id      = aws_launch_template.eks_ng_private.id
    version = aws_launch_template.eks_ng_private.latest_version
  }

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
    create_before_destroy = true
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

