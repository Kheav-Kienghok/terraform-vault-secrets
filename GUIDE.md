# Vault + Terraform + Demo EC2 — Full Walkthrough

## What This Does

```
Your Machine
├── Vault (Docker)     ← stores secrets
├── Terraform          ← manages Vault config + spins up EC2
└── EC2 (AWS)          ← demo instance with Vault CLI pre-installed
```

---

## Prerequisites

| Tool | Install |
|------|---------|
| Docker + Docker Compose | https://docs.docker.com/get-docker |
| Terraform >= 1.5 | `brew install terraform` or https://developer.hashicorp.com/terraform/install |
| AWS CLI | `brew install awscli` |
| AWS credentials | `aws configure` (needs EC2 + SG permissions) |
| An EC2 key pair | Create one in AWS Console → EC2 → Key Pairs, download the `.pem` |

---

## Part 1 — Start Vault Locally

### Step 1: Start the Vault container

```bash
cd vault/
docker compose up -d
```

Vault is now running at **http://127.0.0.1:8200** but is **sealed** (locked). You must initialize and unseal it.

### Step 2: Initialize Vault

```bash
docker exec -it vault vault operator init
```

You will see output like this — **save it somewhere safe**:

```
Unseal Key 1: <key-1>
Unseal Key 2: <key-2>
Unseal Key 3: <key-3>
Unseal Key 4: <key-4>
Unseal Key 5: <key-5>

Initial Root Token: hvs.XXXXXXXXXXXXXXXXXXXXXX
```

> Vault uses **Shamir's Secret Sharing** — you need 3 of 5 keys to unseal it.

### Step 3: Unseal Vault (run 3 times with 3 different keys)

```bash
docker exec -it vault vault operator unseal <Unseal-Key-1>
docker exec -it vault vault operator unseal <Unseal-Key-2>
docker exec -it vault vault operator unseal <Unseal-Key-3>
```

After the third key you should see `Sealed: false`. Vault is now open.

### Step 4: Log in to Vault

```bash
docker exec -it vault vault login <Initial-Root-Token>
```

Or open the UI at http://127.0.0.1:8200 and log in with the root token.

---

## Part 2 — Run Terraform to Manage Secrets

### Step 5: Create your tfvars file

```bash
cd terraform/
cat > terraform.tfvars <<EOF
vault_address = "http://127.0.0.1:8200"
vault_token   = "hvs.XXXXXXXXXXXXXXXXXXXXXX"   # paste your root token here
key_name      = "your-ec2-key-pair-name"       # name of your key pair in AWS
EOF
```

> `terraform.tfvars` is in `.gitignore` — your token will not be committed.

### Step 6: Initialize Terraform

```bash
terraform init
```

This downloads the `hashicorp/vault` and `hashicorp/aws` providers.

### Step 7: Plan — see what Terraform will create

```bash
terraform plan
```

You should see it will:
- Enable the KV v2 secrets engine at `secret/`
- Write a database secret (`username`, `password`, `host`, `port`)
- Launch a demo EC2 instance on AWS
- Create a security group (SSH + HTTP)

### Step 8: Apply

```bash
terraform apply
```

Type `yes` when prompted. After ~2 minutes you will see:

```
Outputs:
db_host     = "localhost"
db_username = "admin"
db_password = <sensitive>
ec2_public_ip = "x.x.x.x"
```

To see the sensitive password:

```bash
terraform output -raw db_password
```

---

## Part 3 — Explore Vault Directly

### Via CLI (from your machine)

```bash
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_TOKEN="hvs.XXXXXXXXXXXXXXXXXXXXXX"

# Check Vault health
vault status

# List all secrets engines
vault secrets list

# Read the database secret Terraform wrote
vault kv get secret/database

# Write your own secret
vault kv put secret/my-app api_key="hello123" env="dev"

# Read it back
vault kv get secret/my-app

# Read just one field
vault kv get -field=api_key secret/my-app

# List secrets at a path
vault kv list secret/

# Delete a secret
vault kv delete secret/my-app
```

### Via the Web UI

1. Open http://127.0.0.1:8200
2. Log in with your root token
3. Navigate to **Secrets → secret/** to browse KV secrets
4. Click any secret to view, edit, or see its version history

---

## Part 4 — Play with the Demo EC2

### Step 9: SSH into the EC2

```bash
ssh -i ~/path/to/your-key.pem ec2-user@<ec2_public_ip>
```

> Get the IP from: `terraform output ec2_public_ip`

### Step 10: Run the pre-loaded demo script

The EC2 was bootstrapped with Vault CLI already installed and env vars set.

```bash
# The demo script walks through common Vault operations
./vault-demo.sh
```

Or run commands manually:

```bash
# These env vars are already set on the EC2
echo $VAULT_ADDR
echo $VAULT_TOKEN

vault status
vault kv get secret/database
vault kv put secret/from-ec2 message="Hello from EC2!"
vault kv get secret/from-ec2
```

> **Note:** The EC2 connects to whatever `vault_address` you set in `terraform.tfvars`.
> For the EC2 to reach your local Vault, you need to either:
> - Use [ngrok](https://ngrok.com/) to expose port 8200: `ngrok http 8200`
> - Or deploy Vault on a public server instead of Docker

---

## Part 5 — Experimenting Further

### Create a new KV secrets engine on a different path

```bash
vault secrets enable -path=myapp kv-v2
vault kv put myapp/config db_url="postgres://..." redis_url="redis://..."
vault kv get myapp/config
```

### Create a read-only policy (least privilege)

```bash
# Write the policy
vault policy write readonly-db - <<EOF
path "secret/data/database" {
  capabilities = ["read"]
}
EOF

# Create a token with only that policy
vault token create -policy="readonly-db"

# Test it — this token can only read, not write
VAULT_TOKEN=<new-token> vault kv get secret/database   # works
VAULT_TOKEN=<new-token> vault kv put secret/database username="hacker"  # denied
```

### See secret version history (KV v2)

```bash
vault kv put secret/database username="admin" password="new-password"
vault kv metadata get secret/database   # shows all versions
vault kv get -version=1 secret/database # read the old version
```

---

## Cleanup

### Destroy all Terraform resources (EC2, security group, Vault secrets)

```bash
cd terraform/
terraform destroy
```

### Stop Vault

```bash
cd ../vault/
docker compose down
```

To also delete Vault's stored data:

```bash
docker compose down -v
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Start Vault | `cd vault && docker compose up -d` |
| Unseal Vault | `docker exec -it vault vault operator unseal <key>` (×3) |
| Terraform apply | `cd terraform && terraform apply` |
| SSH to EC2 | `ssh -i key.pem ec2-user@$(terraform output -raw ec2_public_ip)` |
| Read a secret | `vault kv get secret/<name>` |
| Write a secret | `vault kv put secret/<name> key=value` |
| Open Vault UI | http://127.0.0.1:8200 |
| Destroy all | `terraform destroy` then `docker compose down` |
