# EC2 Instance
resource "aws_instance" "web" {
  ami             = "ami-07a63969ac0961461" # Ubuntu 22.04
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.ec2_sg.id]
  key_name        = "ssh-key-pair" # SSH key to access the instance

  tags = {
    Name = "MyEC2Instance"
  }
}