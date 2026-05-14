output "db_username" {
  value = data.vault_kv_secret_v2.db.data["username"]
}

output "db_host" {
  value = data.vault_kv_secret_v2.db.data["host"]
}

output "db_password" {
  value     = data.vault_kv_secret_v2.db.data["password"]
  sensitive = true
}

output "ec2_public_ip" {
  value       = aws_instance.demo.public_ip
  description = "SSH into the demo EC2: ssh -i <your-key>.pem ec2-user@<this-ip>"
}
