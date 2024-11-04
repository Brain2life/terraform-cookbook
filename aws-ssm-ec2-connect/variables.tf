variable "region" {
  default     = "us-east-1"
  type        = string
  description = "Region target to deploy resources"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "CIDR block of the VPC"
}

variable "common_tags" {
  type = map(string)
  default = {
    Name        = "ssm-private-ec2"
    Environment = "dev"
  }
  description = "Common tags for resources"
}