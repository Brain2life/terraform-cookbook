# Allocate an Elastic IP to be used by the NAT Gateway
resource "aws_eip" "nat_ip" {
  # Set the EIP domain to "vpc" for use in a VPC
  domain = "vpc"

  tags = {
    # Tag to identify the Elastic IP by environment
    Name = "${local.env}-nat-ip"
  }
}

# Create a NAT Gateway to allow internet access for instances in private subnets
resource "aws_nat_gateway" "nat" {
  # Associate the NAT Gateway with the Elastic IP
  allocation_id = aws_eip.nat_ip.id

  # Deploy the NAT Gateway into a public subnet so it can route traffic to the internet
  subnet_id = aws_subnet.public_zone1.id

  tags = {
    # Tag to identify the NAT Gateway by environment
    Name = "${local.env}-nat"
  }

  # Ensure that the Internet Gateway is created before the NAT Gateway
  depends_on = [aws_internet_gateway.igw]
}
