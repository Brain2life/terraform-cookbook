output "bastion_public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Public IP address of the Bastion Host"
}

output "nat_public_ips" {
  value       = data.aws_instances.nat_instances.public_ips
  description = "Public IP addresses of the NAT instances"
}

output "private_instance_ip_first" {
  value       = aws_instance.private[0].private_ip
  description = "Private IP address of the first EC2 instance in private subnet"
}

output "private_instance_ip_second" {
  value       = aws_instance.private[1].private_ip
  description = "Private IP address of the second EC2 instance in private subnet"
}