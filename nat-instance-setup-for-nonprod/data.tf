# Call the external data source to get public IP
data "external" "my_ip" {
  program = ["bash", "./get_public_ip.sh"]
}