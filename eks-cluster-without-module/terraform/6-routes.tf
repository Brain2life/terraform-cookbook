# Route table for private subnets
resource "aws_route_table" "private_rtb" {
  # Associate with the main VPC
  vpc_id = aws_vpc.main.id

  # Route all outbound traffic from private subnets through the NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    # Tag to identify the private route table
    Name = "${local.env}-private-rtb"
  }
}

# Route table for public subnets
resource "aws_route_table" "public_rtb" {
  # Associate with the main VPC
  vpc_id = aws_vpc.main.id

  # Route all outbound traffic from public subnets directly through the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    # Tag to identify the public route table
    Name = "${local.env}-public-rtb"
  }
}

# Associate private subnet in zone1 with private route table
resource "aws_route_table_association" "private_zone1" {
  subnet_id      = aws_subnet.private_zone1.id
  route_table_id = aws_route_table.private_rtb.id
}

# Associate private subnet in zone2 with private route table
resource "aws_route_table_association" "private_zone2" {
  subnet_id      = aws_subnet.private_zone2.id
  route_table_id = aws_route_table.private_rtb.id
}

# Associate public subnet in zone1 with public route table
resource "aws_route_table_association" "public_zone1" {
  subnet_id      = aws_subnet.public_zone1.id
  route_table_id = aws_route_table.public_rtb.id
}

# Associate public subnet in zone2 with public route table
resource "aws_route_table_association" "public_zone2" {
  subnet_id      = aws_subnet.public_zone2.id
  route_table_id = aws_route_table.public_rtb.id
}
