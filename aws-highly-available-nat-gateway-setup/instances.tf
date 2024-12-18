# Bastion host
resource "aws_instance" "bastion" {
  ami             = "ami-07a63969ac0961461" # Ubuntu 22.04
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_a.id # Place into us-east-1a public subnet
  security_groups = [aws_security_group.bastion_sg.id]
  key_name        = "ssh-key-pair" # SSH key name to access Bastion host

  tags = {
    Name = "bastion-host"
  }
}

# EC2 instance in private subnet in us-east-1a
resource "aws_instance" "private_a" {
  ami             = "ami-07a63969ac0961461" # Ubuntu 22.04
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_a.id # Place into us-east-1a private subnet
  security_groups = [aws_security_group.private_sg.id]
  key_name        = "ssh-key-pair"

  tags = {
    Name = "private-instance-a"
  }
}

# EC2 instance in private subnet in us-east-1b
resource "aws_instance" "private_b" {
  ami             = "ami-0c94855ba95c71c99" # Ubuntu 22.04
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_b.id # Place into us-east-1b private subnet
  security_groups = [aws_security_group.private_sg.id]
  key_name        = "ssh-key-pair"

  tags = {
    Name = "private-instance-b"
  }
}
