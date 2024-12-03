# EC2 instance definition
resource "aws_instance" "nginx_instance" {
  ami                  = "ami-0866a3c8686eaeeba" # Ubuntu 24.04 us-east-1
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name
  network_interface {
    network_interface_id = aws_network_interface.private_subnet_interface.id
    device_index         = 0
  }



  tags = {
    Name = "nginx-instance"
  }

  # User data to install Nginx and serve custom HTML
  user_data = <<-EOF
    #!/bin/bash
    mkdir -p /var/www/html
    INSTANCE_PRIVATE_IP=$(TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"` && curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
    echo "<html><body><h1>EC2 instance private IP is $INSTANCE_PRIVATE_IP</h1></body></html>" > /var/www/html/index.html
    cd /var/www/html
    nohup python3 -m http.server 80 > /var/log/python-http-server.log 2>&1 &
  EOF
}