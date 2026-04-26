resource "vault_mount" "kv" {
  path        = "secret"
  type        = "kv"
  description = "KV secrets engine"

  options = {
    version = "2"
  }
}
