# Define reusable locals
locals {
  vpc_id    = aws_vpc.custom_vpc.id
  subnet_id = aws_subnet.private_subnet.id

  services = {
    "ec2messages" : {
      "name" : "com.amazonaws.us-east-1.ec2messages"
    },
    "ssm" : {
      "name" : "com.amazonaws.us-east-1.ssm"
    },
    "ssmmessages" : {
      "name" : "com.amazonaws.us-east-1.ssmmessages"
    }
  }
}