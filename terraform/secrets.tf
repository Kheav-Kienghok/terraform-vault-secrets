resource "vault_kv_secret_v2" "db_secret" {
  mount = vault_mount.kv.path
  name  = "database"

  data_json = jsonencode({
    username = "admin"
    password = "super-secret-password"
    host     = "localhost"
    port     = 5432
  })
}
