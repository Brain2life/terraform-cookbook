resource "aws_internet_gateway" "igw" {
  # Associates the internet gateway with the specified VPC
  vpc_id = aws_vpc.main.id

  tags = {
    # Tag used to identify the internet gateway by environment
    Name = "${local.env}-igw"
  }
}
