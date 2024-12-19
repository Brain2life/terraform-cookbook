# Network ACL
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "${data.external.my_ip.result.ip}/32"
    from_port  = 22
    to_port    = 22
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "${data.external.my_ip.result.ip}/32"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "PublicNACL"
  }
}

# Associate NACL with Subnet
resource "aws_network_acl_association" "public" {
  subnet_id      = aws_subnet.public.id
  network_acl_id = aws_network_acl.public.id
}