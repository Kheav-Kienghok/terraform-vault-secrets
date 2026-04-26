variable "vault_address" {
  type        = string
  description = "Vault server URL"
}

variable "vault_token" {
  type        = string
  description = "Vault root token or Terraform token"
  sensitive   = true
}
