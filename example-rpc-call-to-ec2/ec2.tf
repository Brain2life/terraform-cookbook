# Call the external data source to get your public IP
data "external" "my_ip" {
  program = ["bash", "./get_public_ip.sh"]
}

# EC2 Key Pair (Replace if you have an existing one)
resource "aws_key_pair" "my_ec2_keypair" {
  key_name   = "my-ec2-keypair"
  public_key = file("~/.ssh/aws_test_demo_key.pub") # Replace with the path to your public key
}

# Security Group to allow SSH and RPC traffic
resource "aws_security_group" "rpc_server_sg" {
  name        = "rpc-server-sg"
  description = "Allow SSH and RPC traffic"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_ip.result.ip}/32"] # Restrict to your IP for security
  }

  ingress {
    description = "RPC Port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["${data.external.my_ip.result.ip}/32"] # Restrict to your IP for security
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "rpc_server" {
  ami                         = "ami-06b21ccaeff8cd686" # Amazon Linux 2 AMI in us-east-1
  instance_type               = "t2.micro"
  key_name                    = "my-ec2-keypair" # Replace with your key pair name
  security_groups             = [aws_security_group.rpc_server_sg.name]
  associate_public_ip_address = true

  tags = {
    Name = "RPC Server Instance"
  }

  # User data script to install Python 3
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3
              EOF
}
