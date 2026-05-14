# Vault on EC2 — Full Walkthrough

## What This Does

Terraform spins up a single EC2 instance on AWS. On first boot, the instance
automatically installs Vault, initializes it, unseals it, and loads demo secrets.
You just SSH in and play.

```
AWS
└── EC2 (vault-demo)
    ├── Vault server  (port 8200, file backend)
    ├── Vault UI      (http://<ip>:8200)
    └── Demo secrets  (secret/database, secret/my-app)
```

---

## Prerequisites

| What | How |
|------|-----|
| Terraform >= 1.5 | https://developer.hashicorp.com/terraform/install |
| AWS CLI configured | `aws configure` (needs EC2 + VPC + EIP permissions) |
| EC2 key pair | AWS Console → EC2 → Key Pairs → Create → download `.pem` |

---

## Step 1 — Create your tfvars file

```bash
cd terraform/

cat > terraform.tfvars <<EOF
key_name = "your-key-pair-name"
EOF
```

That's the only required variable. Region defaults to `ap-southeast-1` and
instance type defaults to `t3.micro`. Override if needed:

```hcl
# terraform.tfvars
key_name      = "my-key"
aws_region    = "us-east-1"   # optional
instance_type = "t3.small"    # optional
```

---

## Step 2 — Deploy

```bash
terraform init
terraform apply
```

Type `yes`. Terraform will:
- Launch an EC2 instance (Amazon Linux 2023)
- Attach an Elastic IP (stable public IP)
- Open ports 22 (SSH) and 8200 (Vault)

After ~1 minute you'll see:

```
Outputs:
ssh_command   = "ssh -i <your-key>.pem ec2-user@x.x.x.x"
vault_ui_url  = "http://x.x.x.x:8200"
```

---

## Step 3 — Wait for Vault to boot

The EC2 takes **2–3 minutes** after Terraform finishes to fully bootstrap
(install Vault, initialize, unseal, load demo data). You can watch the log:

```bash
# SSH in first
ssh -i ~/path/to/your-key.pem ec2-user@<ip>

# Then tail the bootstrap log
sudo tail -f /var/log/userdata.log
```

When you see `Bootstrap complete.` it's ready.

---

## Step 4 — Check what's on the EC2

```bash
ls ~
# vault-init.txt   ← unseal keys + root token (keep this safe)
# vault-unseal.sh  ← run after any reboot to unseal Vault
# vault-demo.sh    ← interactive walkthrough script
```

Your shell already has the Vault env vars set:

```bash
echo $VAULT_ADDR    # http://127.0.0.1:8200
echo $VAULT_TOKEN   # your root token
```

---

## Step 5 — Run the demo script

```bash
./vault-demo.sh
```

It walks through:
1. Vault status
2. List secrets engines
3. Read the pre-loaded `secret/database`
4. Read a single field (password)
5. Write your own secret
6. Update it (creates a new version)
7. Read an older version
8. List all secrets
9. Delete the test secret

---

## Step 6 — Open the Vault UI

Take the `vault_ui_url` from the Terraform output and open it in your browser:

```
http://x.x.x.x:8200
```

Log in with the **Token** method. Your root token is in `~/vault-init.txt`:

```bash
cat ~/vault-init.txt | grep "Initial Root Token"
```

From the UI you can browse secrets, create policies, manage auth methods, and
see version history — all visually.

---

## Hands-On Commands to Try

```bash
# Write a secret
vault kv put secret/my-service db_url="postgres://..." port="5432"

# Read it back
vault kv get secret/my-service

# Read just one field
vault kv get -field=db_url secret/my-service

# Update (new version is created automatically)
vault kv put secret/my-service db_url="postgres://new-host/..."

# See all versions
vault kv metadata get secret/my-service

# Read an old version
vault kv get -version=1 secret/my-service

# List everything under secret/
vault kv list secret/

# Delete a secret
vault kv delete secret/my-service

# Create a second secrets engine at a different path
vault secrets enable -path=infra kv-v2
vault kv put infra/aws access_key="AKIA..." region="ap-southeast-1"
vault kv get infra/aws
```

---

## Create a Policy (Least Privilege)

```bash
# Write a policy that allows read-only on secret/database
vault policy write readonly-db - <<EOF
path "secret/data/database" {
  capabilities = ["read"]
}
EOF

# Create a token with that policy
vault token create -policy="readonly-db"

# Test it
VAULT_TOKEN=<new-token> vault kv get secret/database    # works
VAULT_TOKEN=<new-token> vault kv put secret/database x=1  # denied
```

---

## After a Reboot

Vault is sealed on every restart (by design — it protects the data at rest).
Run the unseal script:

```bash
./vault-unseal.sh
```

This replays 2 of your 3 unseal keys automatically.

---

## Cleanup

```bash
# From your local machine (not the EC2)
cd terraform/
terraform destroy
```

This terminates the EC2, releases the Elastic IP, and removes the security group.

---

## Quick Reference

| Action | Command |
|--------|---------|
| SSH in | `ssh -i key.pem ec2-user@<ip>` |
| Run demo | `./vault-demo.sh` |
| Vault status | `vault status` |
| Read a secret | `vault kv get secret/<name>` |
| Write a secret | `vault kv put secret/<name> key=value` |
| List secrets | `vault kv list secret/` |
| Unseal after reboot | `./vault-unseal.sh` |
| Open UI | `http://<ip>:8200` |
| See root token | `cat ~/vault-init.txt` |
| Destroy all | `terraform destroy` |
