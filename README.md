# Terraform + Vault Secrets Demo

This project demonstrates how to use **Terraform** with **HashiCorp Vault** to securely store and retrieve secrets.

---

## Project Structure

- `vault/` → Vault Docker setup  
- `terraform/` → Terraform code (Vault config + secrets)

---

## Setup Steps

1. Start Vault using Docker Compose (`vault/docker-compose.yml`)
2. Initialize Vault and collect:
   - Unseal keys
   - Root token
3. Unseal Vault (3 times)
4. Login to Vault using the root token
5. Configure Terraform by editing `terraform/terraform.tfvars`
6. Run Terraform to:
   - Enable KV secrets engine
   - Store a secret
   - Read the secret back

---

## Vault UI

Vault will be available at:

http://127.0.0.1:8200

---

## Cleanup

Destroy Terraform resources and stop Vault containers when done.
