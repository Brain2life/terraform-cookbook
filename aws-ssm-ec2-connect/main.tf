resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = var.common_tags
}

resource "aws_subnet" "subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, 0) # Derive a subnet with prefix 8 and index 0 from the main VPC’s CIDR block
  tags       = var.common_tags
}

# Set IAM role for EC2 to access AWS SSM
resource "aws_iam_role" "ec2" {
  name               = "ec2"
  tags               = var.common_tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "ssm_managed_ec2" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "ec2_profile"
  role = aws_iam_role.ec2.name
  tags = var.common_tags
}

resource "aws_instance" "ec2" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet.id
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [aws_security_group.ec2_all.id]
  tags = merge(var.common_tags, {
    Name = "ssm_managed_ec2"
  })
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = local.services
  vpc_id   = aws_vpc.main.id

  service_name        = each.value.name
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.ssm_https.id]
  private_dns_enabled = true
  ip_address_type     = "ipv4"
  subnet_ids          = [aws_subnet.subnet.id]
}

resource "aws_security_group" "ssm_https" {
  name        = "allow_ssm"
  description = "Allow SSM traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.subnet.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.common_tags
}

resource "aws_security_group" "ec2_all" {
  name        = "allow all private network"
  description = "allow all private network"
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_subnet.subnet.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.common_tags
}
