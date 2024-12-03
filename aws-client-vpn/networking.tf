# VPC definition
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "custom-private-vpc"
  }
}

# Private subnet definition
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  tags = {
    Name = "private-subnet"
  }
}

# Security group definition
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow ICMP and Web traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSM HTTPS inbount traffic
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2-sg"
  }
}

# Define network interface to connect to private subnet
resource "aws_network_interface" "private_subnet_interface" {
  subnet_id   = aws_subnet.private_subnet.id
  private_ips = ["10.0.1.86"] # Define private IP

  security_groups = [
    aws_security_group.ec2_sg.id
  ]

  tags = {
    Name = "primary-network-interface"
  }
}

# Define VPC endpoint for SSM connection
resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = local.services
  vpc_id   = aws_vpc.custom_vpc.id

  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ec2_sg.id]
  private_dns_enabled = true
  ip_address_type     = "ipv4"
  subnet_ids          = [aws_subnet.private_subnet.id]
}
