#!/bin/bash
set -e
exec >> /var/log/userdata.log 2>&1

# -------------------------------------------------------
# 1. Install Vault
# -------------------------------------------------------
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum -y install vault

# -------------------------------------------------------
# 2. Configure Vault (file backend, no TLS for demo)
# -------------------------------------------------------
mkdir -p /opt/vault/data

cat > /etc/vault.d/vault.hcl <<'VAULTCONF'
ui = true

storage "file" {
  path = "/opt/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

disable_mlock = true
VAULTCONF

chown -R vault:vault /opt/vault /etc/vault.d

# -------------------------------------------------------
# 3. Start Vault
# -------------------------------------------------------
systemctl enable vault
systemctl start vault
sleep 15   # wait for Vault to be ready

export VAULT_ADDR="http://127.0.0.1:8200"

# -------------------------------------------------------
# 4. Initialize Vault (3 keys, need 2 to unseal)
# -------------------------------------------------------
vault operator init -key-shares=3 -key-threshold=2 | tee /home/ec2-user/vault-init.txt

UNSEAL_1=$(grep "Unseal Key 1" /home/ec2-user/vault-init.txt | awk '{print $NF}')
UNSEAL_2=$(grep "Unseal Key 2" /home/ec2-user/vault-init.txt | awk '{print $NF}')
UNSEAL_3=$(grep "Unseal Key 3" /home/ec2-user/vault-init.txt | awk '{print $NF}')
ROOT_TOKEN=$(grep "Initial Root Token" /home/ec2-user/vault-init.txt | awk '{print $NF}')

# -------------------------------------------------------
# 5. Unseal Vault (provide 2 of the 3 keys)
# -------------------------------------------------------
vault operator unseal "$UNSEAL_1"
vault operator unseal "$UNSEAL_2"

export VAULT_TOKEN="$ROOT_TOKEN"

# -------------------------------------------------------
# 6. Set env vars for ec2-user so vault CLI just works
# -------------------------------------------------------
cat >> /home/ec2-user/.bashrc <<ENVEOF

# Vault
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$ROOT_TOKEN
ENVEOF

# -------------------------------------------------------
# 7. Load demo secrets into Vault
# -------------------------------------------------------
vault secrets enable -path=secret kv-v2

vault kv put secret/database \
  username="admin" \
  password="super-secret-password" \
  host="db.internal" \
  port="5432"

vault kv put secret/my-app \
  api_key="abc123" \
  env="dev" \
  version="1.0"

# -------------------------------------------------------
# 8. Create helper scripts for ec2-user
# -------------------------------------------------------

# vault-unseal.sh  — run this after an EC2 reboot
cat > /home/ec2-user/vault-unseal.sh <<UNSEALEOF
#!/bin/bash
export VAULT_ADDR=http://127.0.0.1:8200
vault operator unseal $UNSEAL_1
vault operator unseal $UNSEAL_2
echo "Vault is unsealed."
UNSEALEOF

# vault-demo.sh  — interactive walkthrough
cat > /home/ec2-user/vault-demo.sh <<'DEMOEOF'
#!/bin/bash
echo "==============================="
echo "  Vault Demo"
echo "==============================="

echo ""
echo "--- 1. Vault Status ---"
vault status

echo ""
echo "--- 2. List Secrets Engines ---"
vault secrets list

echo ""
echo "--- 3. Read the database secret ---"
vault kv get secret/database

echo ""
echo "--- 4. Read just the password field ---"
vault kv get -field=password secret/database

echo ""
echo "--- 5. Write your own secret ---"
vault kv put secret/my-test message="Hello from demo!" owner="me"
vault kv get secret/my-test

echo ""
echo "--- 6. Update a secret (creates a new version) ---"
vault kv put secret/my-test message="Updated!" owner="me"
vault kv metadata get secret/my-test

echo ""
echo "--- 7. Read an older version ---"
vault kv get -version=1 secret/my-test

echo ""
echo "--- 8. List all secrets ---"
vault kv list secret/

echo ""
echo "--- 9. Delete the test secret ---"
vault kv delete secret/my-test
echo "Done! Explore more with: vault kv --help"
DEMOEOF

chmod +x /home/ec2-user/vault-unseal.sh /home/ec2-user/vault-demo.sh
chown ec2-user:ec2-user \
  /home/ec2-user/vault-init.txt \
  /home/ec2-user/vault-unseal.sh \
  /home/ec2-user/vault-demo.sh

echo "Bootstrap complete." >> /var/log/userdata.log
