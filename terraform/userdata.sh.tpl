#!/bin/bash
set -e

# Install Vault CLI
yum install -y yum-utils
yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
yum install -y vault

# Set Vault env vars so vault CLI works out of the box
echo "export VAULT_ADDR=${vault_address}" >> /etc/profile.d/vault.sh
echo "export VAULT_TOKEN=${vault_token}" >> /etc/profile.d/vault.sh

# Write a demo script the user can run
cat <<'EOF' > /home/ec2-user/vault-demo.sh
#!/bin/bash
echo "=== Vault Demo Script ==="
echo ""

echo "1. Check Vault status:"
vault status

echo ""
echo "2. List secrets engines:"
vault secrets list

echo ""
echo "3. Read the database secret:"
vault kv get secret/database

echo ""
echo "4. Write a new test secret:"
vault kv put secret/my-app api_key="abc123" debug="true"

echo ""
echo "5. Read it back:"
vault kv get secret/my-app

echo ""
echo "6. Delete the test secret:"
vault kv delete secret/my-app
echo "Done!"
EOF

chmod +x /home/ec2-user/vault-demo.sh
chown ec2-user:ec2-user /home/ec2-user/vault-demo.sh

# Signal completion
echo "Vault demo EC2 ready." > /var/log/vault-demo-ready.log
