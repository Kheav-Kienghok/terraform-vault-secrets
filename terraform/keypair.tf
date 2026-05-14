resource "tls_private_key" "vault" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "vault" {
  key_name   = "vault-demo-key"
  public_key = tls_private_key.vault.public_key_openssh
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.vault.private_key_pem
  filename        = "${path.root}/../secret/vault-demo.pem"
  file_permission = "0400"
}
