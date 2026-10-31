# System Node Group (For AI Gateway, Redis, Qdrant, CoreDNS)
resource "aws_eks_node_group" "system_nodes" {
  cluster_name    = aws_eks_cluster.ai_cluster.name
  node_group_name = "${var.cluster_name}-system-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  instance_types = [var.system_instance_type]
  capacity_type  = "SPOT" # 70% cheaper than On-Demand (~$0.015/hr)

  scaling_config {
    desired_size = 1
    min_size     = 1
    max_size     = 2
  }

  labels = {
    role = "system-platform"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# GPU Node Group (For vLLM / Ollama with NVIDIA T4)
resource "aws_eks_node_group" "gpu_nodes" {
  cluster_name    = aws_eks_cluster.ai_cluster.name
  node_group_name = "${var.cluster_name}-gpu-nodes"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  instance_types = [var.gpu_instance_type]
  capacity_type  = "SPOT"            # Spot GPU (~$0.16/hr vs $0.526 on-demand)
  ami_type       = "AL2_x86_64_GPU"   # Pre-installed NVIDIA drivers and CUDA runtime

  scaling_config {
    desired_size = 1
    min_size     = 0
    max_size     = 1
  }

  labels = {
    role                = "gpu-inference"
    "accelerator-type"  = "nvidia-t4"
  }

  taint {
    key    = "nvidia.com/gpu"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

