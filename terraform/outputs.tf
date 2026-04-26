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
