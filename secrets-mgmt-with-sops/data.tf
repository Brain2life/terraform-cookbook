data "sops_file" "db_credentials" {
  source_file = "${path.module}/secrets.enc.json"
}
