# Data block to get the default VPC ID
data "aws_vpc" "default" {
  default = true
}

# Call the external data source to get public IP
data "external" "my_ip" {
  program = ["bash", "./get_public_ip.sh"]
}

# Security Group for Bastion Host
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-host-sg"
  vpc_id = data.aws_vpc.default.id

  # Allow SSH access from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_ip.result.ip}/32"]
  }

  # Outbound traffic (allow all)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion Security Group"
  }
}

# EC2 Key Pair (Replace if you have an existing one)
resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = file("~/.ssh/aws_test_demo_key.pub")  # Replace with the path to your public key
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = "ami-005fc0f236362e99f"  # Ubuntu 22.04 AMI (change for your region)
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.bastion_key.key_name
  associate_public_ip_address = true  # Ensure public IP

  security_groups = [aws_security_group.bastion_sg.name]

  # Install MySQL client via user data script
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install mysql-server -y
              EOF

  tags = {
    Name = "Bastion Host"
  }
}