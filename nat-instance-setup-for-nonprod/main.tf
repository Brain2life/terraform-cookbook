# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "two-az-nat-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-internet-gateway"
  }
}

# Public Subnets (Two AZs)
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index) # 10.0.0.0/24 and 10.0.1.0/24
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Private Subnets (Two AZs)
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2) # 10.0.2.0/24 and 10.0.3.0/24
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate Public Route Table with Public Subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Security Group for NAT Instances
resource "aws_security_group" "nat_instance" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.main.cidr_block] # Allow ICMP traffic in VPC
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_ip.result.ip}/32"] # Restrict to your IP 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "nat-instance-sg"
  }
}

# Security Group for Private EC2 Instances
resource "aws_security_group" "private_instance" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id] # Allow Bastion SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-ec2-sg"
  }
}

# Launch Template for NAT Instances
resource "aws_launch_template" "nat" {
  name_prefix = "nat-instance"

  image_id      = "ami-0453ec754f44f9a4a" # Amazon Linux 2023
  instance_type = "t3.micro"
  key_name      = "ssh-key-pair"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat_instance.id]
  }

  # Configure NAT service
  user_data = filebase64("configure_nat.sh")

  tags = {
    Name = "nat-instance-template"
  }
}

# Auto Scaling Groups for NAT Instances (One per AZ)
resource "aws_autoscaling_group" "nat" {
  count               = 2
  vpc_zone_identifier = [aws_subnet.public[count.index].id]

  launch_template {
    id      = aws_launch_template.nat.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  tag {
    key                 = "Name"
    value               = "nat-instance-asg-${count.index + 1}"
    propagate_at_launch = true
  }
}

# Private EC2 Instances (One per Private Subnet)
resource "aws_instance" "private" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private[count.index].id
  key_name      = "ssh-key-pair"
  security_groups = [
    aws_security_group.private_instance.id
  ]

  tags = {
    Name = "private-ec2-${count.index + 1}"
  }
}

# Data Source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Retrieve NAT Instances in Public Subnet
data "aws_instances" "nat_instances" {

  depends_on = [aws_autoscaling_group.nat] # Ensure ASG is created first

  filter {
    name   = "tag:Name"
    values = ["nat-instance-asg-*"] # Matches the Name tag applied during launch
  }

  filter {
    name   = "instance-state-name"
    values = ["running"] # Only retrieve running instances
  }
}

# Define route tables for resources in private subnets
resource "aws_route_table" "private" {
  count = 2

  vpc_id = aws_vpc.main.id

  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = data.aws_instances.nat_instances.ids[0] # Go to Internet via NAT instance target
  }
}

# Associate Private Route Tables with Private Subnets
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}