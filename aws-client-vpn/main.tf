# Provision Client VPN
module "vpn-client" {
  source            = "babicamir/vpn-client/aws"
  version           = "1.0.1"
  organization_name = "MinionEnterprise"
  project-name      = "Fun"
  environment       = "dev"
  # Network information
  vpc_id            = local.vpc_id
  subnet_id         = local.subnet_id
  client_cidr_block = "172.0.0.0/22" # It must be different from the primary VPC CIDR
  # VPN config options
  split_tunnel           = "true" # 'true' - set if you want Internet and other network connections to be available, otherwise restrict only to VPN connection
  vpn_inactive_period    = "300"  # seconds
  session_timeout_hours  = "8"    # Expected values 8, 10, 12, 24h
  logs_retention_in_days = "7"
  # List of users to be created
  aws-vpn-client-list = ["root", "devs"] #Do not delete "root" user!
}