data "vault_kv_secret_v2" "db" {
  mount = vault_mount.kv.path
  name  = "database"

  depends_on = [vault_kv_secret_v2.db_secret]
}
