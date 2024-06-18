resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = "terraform-generated-key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "local_file" "private_key_file" {
  content         = tls_private_key.example.private_key_pem
  filename        = "${path.module}/generated-ssh-key.pem"
  file_permission = "0600"
}

output "key_name" {
  value = aws_key_pair.generated_key.key_name
}