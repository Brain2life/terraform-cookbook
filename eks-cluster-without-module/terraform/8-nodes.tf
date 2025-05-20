# Defines an IAM role for EKS worker nodes, allowing EC2 instances to assume the role
# to interact with the EKS cluster and other AWS services.
resource "aws_iam_role" "nodes" {
  name = "${local.env}-${local.eks_name}-eks-nodes"

  # Trust policy that allows the EC2 service (ec2.amazonaws.com) to assume this role
  # This is required for worker nodes (EC2 instances) to authenticate with the EKS cluster
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# Attaches the AmazonEKSWorkerNodePolicy to the worker node IAM role
# This policy grants permissions for worker nodes to communicate with the EKS control plane
resource "aws_iam_role_policy_attachment" "amazon_eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

# Attaches the AmazonEKS_CNI_Policy to the worker node IAM role
# This policy grants permissions for the AWS VPC CNI plugin to manage networking for pods
resource "aws_iam_role_policy_attachment" "amazon_eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

# Attaches the AmazonEC2ContainerRegistryReadOnly policy to the worker node IAM role
# This policy allows worker nodes to pull container images from Amazon ECR
resource "aws_iam_role_policy_attachment" "amazon_ec2_container_registry_read_only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

# Defines an EKS node group, which manages a group of worker nodes (EC2 instances) for the EKS cluster
resource "aws_eks_node_group" "general" {
  cluster_name    = aws_eks_cluster.eks.name
  version         = local.eks_version
  node_group_name = "general"
  node_role_arn   = aws_iam_role.nodes.arn

  # Specifies the subnets where worker nodes (EC2 instances) will be launched
  # Includes two private subnets across two availability zones
  subnet_ids = [
    aws_subnet.private_zone1.id,
    aws_subnet.private_zone2.id
  ]

  # Sets the capacity type to ON_DEMAND for predictable performance
  capacity_type = "ON_DEMAND"
  # Specifies the instance type for worker nodes (t3.small for cost-effective compute)
  instance_types = ["t3.small"]

  # Configures the scaling parameters for the node group used by Cluster Autoscaler
  scaling_config {
    desired_size = 1
    max_size     = 3
    min_size     = 1
  }

  # Configures update behavior to minimize disruption during node group updates
  update_config {
    # Allows only one node to be unavailable during rolling updates
    max_unavailable = 1
  }

  # Adds a label to the worker nodes for workload scheduling (e.g., for pod placement, affinity)
  labels = {
    role = "general"
  }

  # Ensures IAM role policies are attached before creating the node group
  depends_on = [
    aws_iam_role_policy_attachment.amazon_eks_worker_node_policy,
    aws_iam_role_policy_attachment.amazon_eks_cni_policy,
    aws_iam_role_policy_attachment.amazon_ec2_container_registry_read_only
  ]

  # Lifecycle block to ignore changes to desired_size, allowing external tools (e.g., Cluster Autoscaler) to manage scaling
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}