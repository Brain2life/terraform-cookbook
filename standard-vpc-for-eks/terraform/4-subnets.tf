# Private subnet in zone1
resource "aws_subnet" "private_zone1" {
  # Associate the subnet with the main VPC
  vpc_id = aws_vpc.main.id

  # Private subnet CIDR block (first /20 block in VPC)
  cidr_block        = "10.0.0.0/20"
  availability_zone = local.zone1

  tags = {
    # Tag for identification
    Name = "${local.env}-private-${local.zone1}"

    # Used by Kubernetes to mark as internal load balancer subnet
    "kubernetes.io/role/internal-elb" = "1"

    # Used only by EKS service to recognize the subnet
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# Private subnet in zone2
resource "aws_subnet" "private_zone2" {
  vpc_id = aws_vpc.main.id

  # Next /20 block, non-overlapping with private_zone1
  cidr_block        = "10.0.16.0/20"
  availability_zone = local.zone2

  tags = {
    Name                                                   = "${local.env}-private-${local.zone2}"
    "kubernetes.io/role/internal-elb"                      = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# Public subnet in zone1
resource "aws_subnet" "public_zone1" {
  vpc_id = aws_vpc.main.id

  # Public subnet CIDR block, after private ranges
  cidr_block        = "10.0.32.0/20"
  availability_zone = local.zone1

  # Enables automatic public IP assignment for launched instances
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.env}-public-${local.zone1}"

    # Tag for public load balancer use in Kubernetes
    "kubernetes.io/role/elb" = "1"

    # EKS cluster discovery
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# Public subnet in zone2
resource "aws_subnet" "public_zone2" {
  vpc_id = aws_vpc.main.id

  # Next /20 block for public zone2, non-overlapping
  cidr_block        = "10.0.48.0/20"
  availability_zone = local.zone2

  map_public_ip_on_launch = true

  tags = {
    Name                                                   = "${local.env}-public-${local.zone2}"
    "kubernetes.io/role/elb"                               = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}
