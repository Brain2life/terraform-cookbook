# Public IP of Bastion host
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}

# Private IP of EC2 instance in private subnet us-east-1a
output "private_instance_a_private_ip" {
  value = aws_instance.private_a.private_ip
}

# Private IP of EC2 instance in private subnet us-east-1b
output "private_instance_b_private_ip" {
  value = aws_instance.private_b.private_ip
}

# Public IP of NAT Gateway in us-east-1a
output "nat_gateway_a_eip" {
  value = aws_eip.nat_a.public_ip
}

# Public IP of NAT Gateway in us-east-1b
output "nat_gateway_b_eip" {
  value = aws_eip.nat_b.public_ip
}