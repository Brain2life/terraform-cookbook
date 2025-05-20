resource "aws_vpc" "main" {
  # The IP range for the VPC in CIDR notation
  cidr_block = "10.0.0.0/16"

  # Enables DNS resolution via the Amazon-provided DNS server.
  # Must be true for EC2 instances and EKS pods to resolve domain names.
  enable_dns_support = true

  # Enables DNS hostnames for instances launched in the VPC.
  # Required for assigning internal DNS names (e.g., ip-10-0-0-1.ec2.internal).
  enable_dns_hostnames = true

  tags = {
    # Tag used to identify the VPC by name. This tag will be visible in AWS Console by default
    Name = "${local.env}-vpc"
  }
}
