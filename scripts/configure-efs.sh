#!/bin/bash
# Dynamic EFS Configuration Script
# Retrieves EFS DNS name from Terraform output and updates NFS provisioner

set -e

echo "========================================"
echo "Dynamic EFS Configuration"
echo "========================================"

# Get EFS DNS from Terraform output
echo "[1/2] Retrieving EFS DNS from Terraform..."
cd terraform/aws-eks

if [ ! -f "terraform.tfstate" ]; then
    echo "❌ Error: terraform.tfstate not found. Run terraform apply first."
    exit 1
fi

EFS_DNS=$(terraform output -raw efs_dns_name 2>/dev/null)

if [ -z "$EFS_DNS" ]; then
    echo "❌ Error: Could not retrieve EFS DNS from Terraform output"
    exit 1
fi

echo "✅ EFS DNS: $EFS_DNS"

# Update NFS provisioner
echo ""
echo "[2/2] Updating NFS provisioner configuration..."
cd ../..

PROVISIONER_FILE="storage/nfs/provisioner.yaml"

if [ ! -f "$PROVISIONER_FILE" ]; then
    echo "❌ Error: $PROVISIONER_FILE not found"
    exit 1
fi

# Backup original
cp "$PROVISIONER_FILE" "$PROVISIONER_FILE.backup"

# Replace EFS DNS (both occurrences)
sed -i "s|value:.*\.efs\..*\.amazonaws\.com|value: $EFS_DNS|g" "$PROVISIONER_FILE"
sed -i "s|server:.*\.efs\..*\.amazonaws\.com|server: $EFS_DNS|g" "$PROVISIONER_FILE"

echo "✅ NFS provisioner updated"
echo "   Backup saved: $PROVISIONER_FILE.backup"

echo ""
echo "========================================"
echo "✅ Configuration Complete!"
echo "========================================" echo ""
echo "NFS Provisioner is now configured with:"
echo "  EFS DNS: $EFS_DNS"
echo ""
echo "Apply the updated configuration:"
echo "  kubectl apply -f $PROVISIONER_FILE"
echo ""
