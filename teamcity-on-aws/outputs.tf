output "teamcity_server_public_ip" {
  description = "The public IP address of the TeamCity server"
  value       = aws_instance.teamcity_server.public_ip
}

output "teamcity_agent_public_ips" {
  description = "The public IP addresses of the TeamCity build agents"
  value       = aws_instance.teamcity_agent[*].public_ip
}