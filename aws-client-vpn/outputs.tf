# Output EC2 private IP
output "ec2_private_ip" {
  value = aws_instance.nginx_instance.private_ip
}