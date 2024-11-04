output "ami_amazon_linux2_arn" {
  value       = data.aws_ami.amazon_linux_2.arn
  description = "ARN of the Amazon Linux 2 AMI"
}

output "ec2_arn" {
  value       = aws_instance.ec2.arn
  description = "ARN of the EC2 instance"
}

output "vpc_arn" {
  value       = aws_vpc.main.arn
  description = "ARB of the VPC"
}