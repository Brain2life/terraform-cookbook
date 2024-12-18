# Provision Elastic IP for NAT Gateway in us-east-1a
resource "aws_eip" "nat_a" {
  vpc = true
}

# Provision NAT Gateway in us-east-1a
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name = "nat-gateway-a"
  }
}

# Provision Elastic IP for NAT Gateway in us-east-1b
resource "aws_eip" "nat_b" {
  vpc = true
}

# Provision NAT Gateway in us-east-1b
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
  tags = {
    Name = "nat-gateway-b"
  }
}