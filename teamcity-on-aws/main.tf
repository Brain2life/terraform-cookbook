terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    time = {
      source = "hashicorp/time"
      version = "0.11.2"
    }

  }
}

provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

resource "aws_instance" "teamcity_server" {
  ami           = "ami-0c819f65440d5f1d1" # Ubuntu 20.04 amd64 us-east-1
  instance_type = "t3.medium"
  key_name      = "terraform-generated-key" # Replace with your key pair name

  tags = {
    Name = "TeamCityServer"
  }

  user_data = <<-EOF
              #!/bin/bash
              adduser teamcity
              apt update && apt install wget -y
              cd /opt
              wget https://download.jetbrains.com/teamcity/TeamCity-2022.10.1.tar.gz
              tar xfz TeamCity-2022.10.1.tar.gz
              apt install java-common -y
              wget https://corretto.aws/downloads/latest/amazon-corretto-11-x64-linux-jdk.deb
              dpkg --install amazon-corretto-11-x64-linux-jdk.deb
              chown -R teamcity:teamcity TeamCity
              su teamcity
              TeamCity/bin/runAll.sh start
              EOF

  vpc_security_group_ids = [aws_security_group.teamcity_sg.id]
}

# Delay resource to wait for the TeamCity server to start
resource "time_sleep" "wait_for_teamcity_server" {
  depends_on = [aws_instance.teamcity_server]

  create_duration = "5m" # Wait for 5 minutes
}

# TeamCity Build Agent
resource "aws_instance" "teamcity_agent" {
  count         = 2 # Number of build agents
  ami           = "ami-0c819f65440d5f1d1" # Ubuntu 20.04 amd64 us-east-1
  instance_type = "t3.medium"
  key_name      = "terraform-generated-key" # Replace with your key pair name

  tags = {
    Name = "TeamCityAgent"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              usermod -aG docker ubuntu
              docker run -d -e SERVER_URL="http://$(aws_instance.teamcity_server.public_ip):8111" \
                -v /data/teamcity_agent/conf:/data/teamcity_agent/conf \
                jetbrains/teamcity-agent
              EOF

  vpc_security_group_ids = [aws_security_group.teamcity_sg.id]
}

resource "aws_security_group" "teamcity_sg" {
  name        = "teamcity_sg"
  description = "Allow SSH and TeamCity traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your_public_ip_address>/32"]
  }

  ingress {
    from_port   = 8111
    to_port     = 8111
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
