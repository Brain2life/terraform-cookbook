# Define commonly used values across the module
locals {
  env         = "dev"
  region      = "us-east-1"
  zone1       = "us-east-1a"
  zone2       = "us-east-1b"
  eks_name    = "eks_cluster"
  eks_version = "1.32" # EKS supported Kubernetes version
}