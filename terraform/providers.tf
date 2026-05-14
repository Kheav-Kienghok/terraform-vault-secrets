provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

provider "aws" {
  region = "ap-southeast-1"
}
