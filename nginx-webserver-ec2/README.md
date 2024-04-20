# Deploy nginx based web server on AWS EC2 instance

This terraform template deploys single EC2 instance with Nginx web server installed and running. The web server opens `HTTP 80` and `SSH 22` ports for access. SSH key and EC2 instances are deployed via respective separate folders.

Deployment steps:
1. First deploy SSH key and obtain the generated private key
2. Deploy EC2 instance with SSH key linked in the previous step

AWS Terraform provider version is locked with `5.45.0` version.

## Explanation of `key_pair.tf`
- **TLS Private Key Resource**: The `tls_private_key` resource from the `tls` provider is used to generate a private RSA key.
- **AWS Key Pair Resource**: The `aws_key_pair` resource uploads the generated public key to AWS under the specified key name. This allows you to use this key pair for EC2 instances.
- **Output**: The private key is outputted for your use. It’s marked as sensitive to prevent it from being displayed in the logs.

## References:
- [Amazon EC2 Ubuntu AMI Locator](https://cloud-images.ubuntu.com/locator/ec2/)