output "vault_ui_url" {
  value       = "http://${aws_eip.vault.public_ip}:8200"
  description = "Open this in your browser to access the Vault UI"
}

output "ssh_command" {
  value       = "ssh -i ../secret/vault-demo.pem ec2-user@${aws_eip.vault.public_ip}"
  description = "Command to SSH into the Vault EC2"
}
