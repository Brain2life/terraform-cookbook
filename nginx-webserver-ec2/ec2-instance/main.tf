terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.45.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web_server" {
  ami           = "ami-061612d72693df8ce"  # Update this to the latest Ubuntu AMI in your region. This AMI is Ubuntu 20.04 Focal Fossa
  instance_type = "t2.micro"
  key_name      = "terraform-generated-key"  # Use the name of your existing key pair

  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y nginx
              echo 'Hello from Web Server!' | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "WebServer"
  }
}

output "public_ip" {
  value = aws_instance.web_server.public_ip
  description = "The public IP address of the web server."
}