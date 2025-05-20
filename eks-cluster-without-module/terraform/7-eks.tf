# Defines an IAM role for the EKS cluster, which allows the EKS service to assume the role
# to manage AWS resources on behalf of the cluster.
resource "aws_iam_role" "eks" {
  # Name of the IAM role, dynamically constructed using environment and cluster name variables
  name = "${local.env}-${local.eks_name}-eks-cluster"

  # Trust policy that allows the EKS service (eks.amazonaws.com) to assume this role
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "eks.amazonaws.com"
      }
    }
  ]
}
POLICY
}

# Attaches the AmazonEKSClusterPolicy to the EKS IAM role to grant necessary permissions
# for the EKS service to manage cluster resources like load balancers and networking.
resource "aws_iam_role_policy_attachment" "eks" {
  # ARN of the AWS-managed policy for EKS clusters
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  # References the name of the IAM role created above
  role = aws_iam_role.eks.name
}

# Defines the EKS cluster resource, which provisions and configures the Kubernetes control plane.
resource "aws_eks_cluster" "eks" {
  # Cluster name, dynamically constructed using environment and cluster name variables
  name = "${local.env}-${local.eks_name}"
  # Specifies the Kubernetes version for the cluster, sourced from a local variable
  version = local.eks_version
  # References the ARN of the IAM role created above, used by EKS to manage resources
  role_arn = aws_iam_role.eks.arn

  # Configures the VPC settings for the EKS cluster
  vpc_config {
    # Disables private access to the Kubernetes API server (accessible only via public internet)
    endpoint_private_access = false
    # Enables public access to the Kubernetes API server
    endpoint_public_access = true

    # Specifies the subnet IDs for the EKS control plane, using private subnets in two availability zones
    subnet_ids = [
      aws_subnet.private_zone1.id,
      aws_subnet.private_zone2.id
    ]
  }

  # Configures access settings for the EKS cluster
  access_config {
    # Sets authentication to use AWS IAM exclusively for Kubernetes API access
    authentication_mode = "API"
    # Automatically grants the IAM entity creating the cluster full Kubernetes admin privileges
    bootstrap_cluster_creator_admin_permissions = true
  }

  # Ensures the IAM role policy attachment is created before the EKS cluster
  depends_on = [aws_iam_role_policy_attachment.eks]
}