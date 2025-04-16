# terraform-cookbook

![](./img/terraform-logo.png)

[HashiCorp Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) is an infrastructure as code tool that lets you define both cloud and on-prem resources in human-readable configuration files that you can version, 
reuse, and share. You can then use a consistent workflow to provision and manage all of your infrastructure throughout its lifecycle. 
Terraform can manage low-level components like compute, storage, and networking resources, as well as high-level components like 
DNS entries and SaaS features.

## Templates
- [Deploy single EC2 instance with SSH keys generated and NGINX web server installed](./nginx-webserver-ec2/)
- [TeamCity deployed on AWS](./teamcity-on-aws/)
- [Terraform remote state S3 backend and DynamoDB for state locking](./s3-dynamodb-backend/)
- [Use open-source SOPS tool to handle sensitive values in Terraform code](./secrets-mgmt-with-sops/)
- [Use AWS Secrets Manager to handle sensitive values in Terraform code](./aws-secrets-manager/)
- [Example of making Remote Procedure Call to a service running on a remote EC2 instance](./example-rpc-call-to-ec2/)
- [Use AWS SSM Session Manager to connect to EC2 instance in private subnet](./aws-ssm-ec2-connect/)
- [Provision AWS Client VPN to access private resources in VPC](./aws-client-vpn/)
- [Provision NAT instance for non-prod workloads](./nat-instance-setup-for-nonprod/)
- [Example setup of AWS NAT Gateway with high availability](./aws-highly-available-nat-gateway-setup/)
- [Basics of AWS NACLs and Securuty Groups](./aws-nacl-basics/)
- [EKS with Managed Node Groups](./eks-with-managed-node-group/)