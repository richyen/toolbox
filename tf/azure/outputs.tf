output "public_ip_address" {
  description = "Public IP address assigned to the Debian VM."
  value       = azurerm_public_ip.main.ip_address
}

output "ssh_connection_command" {
  description = "SSH command for connecting to the Debian VM."
  value       = "ssh -i ${local.ssh_private_key_path} ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}
