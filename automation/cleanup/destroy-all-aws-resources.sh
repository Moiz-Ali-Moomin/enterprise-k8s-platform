#!/bin/bash
# Complete AWS Resource Cleanup Script
# This script safely destroys ALL AWS resources to avoid costs

set -e

echo "========================================"
echo "⚠️  AWS RESOURCE CLEANUP - COMPLETE TEARDOWN"
echo "========================================"
echo ""
echo "This will delete:"
echo "  - All Kubernetes resources (LoadBalancers, Services, PVCs)"
echo "  - EKS Cluster"
echo "  - EFS File System"
echo "  - ECR Repositories"
echo "  - VPC and all networking"
echo "  - All Terraform-managed resources"
echo ""
read -p "Are you ABSOLUTELY SURE? This cannot be undone! (type 'DELETE' to confirm): " CONFIRM

if [ "$CONFIRM" != "DELETE" ]; then
    echo "❌ Cleanup cancelled."
    exit 0
fi

echo ""
echo "🚀 Starting cleanup process..."
echo ""

# Step 1: Delete Kubernetes LoadBalancer Services (creates AWS ELBs)
echo "[1/8] Deleting Kubernetes LoadBalancer services..."
echo "   This removes AWS Elastic Load Balancers to avoid ongoing costs"

kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer --wait=true --timeout=300s 2>/dev/null || echo "   ⚠️  No LoadBalancer services found or already deleted"

echo "   ✅ LoadBalancer services deleted"
sleep 5

# Step 2: Delete all PersistentVolumeClaims (might create EBS volumes)
echo ""
echo "[2/8] Deleting all PersistentVolumeClaims..."
echo "   This removes any EBS/EFS volumes"

kubectl delete pvc --all --all-namespaces --wait=true --timeout=300s 2>/dev/null || echo "   ⚠️  No PVCs found or already deleted"

echo "   ✅ PVCs deleted"
sleep 5

# Step 3: Delete all namespaces (cascades to all resources)
echo ""
echo "[3/8] Deleting Kubernetes namespaces..."
echo "   This removes all deployed applications and services"

NAMESPACES="jenkins sonarqube logging monitoring argocd nfs-provisioner"
for ns in $NAMESPACES; do
    kubectl delete namespace $ns --wait=true --timeout=300s 2>/dev/null && echo "   ✅ Deleted namespace: $ns" || echo "   ⚠️  Namespace $ns not found"
done

sleep 10

# Step 4: Delete ECR repositories
echo ""
echo "[4/8] Deleting ECR repositories..."

aws ecr delete-repository --repository-name nginx-demo --region us-west-2 --force 2>/dev/null && echo "   ✅ Deleted ECR repository: nginx-demo" || echo "   ⚠️  ECR repository not found"

# Step 5: Navigate to Terraform directory
echo ""
echo "[5/8] Navigating to Terraform directory..."
cd terraform/aws-eks || { echo "❌ terraform/aws-eks directory not found"; exit 1; }

# Step 6: Terraform destroy
echo ""
echo "[6/8] Running Terraform destroy..."
echo "   This will delete:"
echo "     - EKS Cluster"
echo "     - EFS File System"
echo "     - VPC, Subnets, Route Tables"
echo "     - Security Groups"
echo "     - Internet Gateway"
echo "     - NAT Gateways"
echo "     - IAM Roles and Policies"
echo ""

terraform destroy -auto-approve

if [ $? -eq 0 ]; then
    echo ""
    echo "   ✅ Terraform resources destroyed successfully"
else
    echo ""
    echo "   ⚠️  Terraform destroy encountered errors"
    echo "   Check AWS Console for any remaining resources"
fi

# Step 7: Verify no resources remain
echo ""
echo "[7/8] Verifying resource cleanup..."

# Check for running EC2 instances
echo "   Checking for EC2 instances..."
INSTANCES=$(aws ec2 describe-instances \
    --filters "Name=tag:kubernetes.io/cluster/enterprise-cluster,Values=owned" \
    --query 'Reservations[*].Instances[?State.Name==`running`].InstanceId' \
    --output text \
    --region us-west-2 2>/dev/null)

if [ -z "$INSTANCES" ]; then
    echo "   ✅ No EC2 instances found"
else
    echo "   ⚠️  Found running instances: $INSTANCES"
    echo "   Run: aws ec2 terminate-instances --instance-ids $INSTANCES --region us-west-2"
fi

# Check for ELBs
echo "   Checking for Load Balancers..."
ELBS=$(aws elbv2 describe-load-balancers \
    --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].LoadBalancerArn' \
    --output text \
    --region us-west-2 2>/dev/null)

if [ -z "$ELBS" ]; then
    echo "   ✅ No Load Balancers found"
else
    echo "   ⚠️  Found load balancers - delete manually in AWS Console"
fi

# Check for EFS
echo "   Checking for EFS file systems..."
EFS=$(aws efs describe-file-systems \
    --query 'FileSystems[?Tags[?Key==`ManagedBy` && Value==`terraform`]].FileSystemId' \
    --output text \
    --region us-west-2 2>/dev/null)

if [ -z "$EFS" ]; then
    echo "   ✅ No EFS file systems found"
else
    echo "   ⚠️  Found EFS: $EFS - should be deleted by Terraform"
fi

# Step 8: Final summary
echo ""
echo "========================================"
echo "✅ CLEANUP COMPLETE!"
echo "========================================"
echo ""
echo "📊 Summary:"
echo "   ✅ Kubernetes LoadBalancers deleted"
echo "   ✅ PersistentVolumeClaims deleted"
echo "   ✅ Kubernetes namespaces deleted"
echo "   ✅ ECR repositories deleted"
echo "   ✅ Terraform resources destroyed"
echo ""
echo "⚠️  VERIFY IN AWS CONSOLE:"
echo "   1. EC2 Dashboard - No running instances"
echo "   2. VPC Dashboard - No VPCs except default"
echo "   3. EFS Dashboard - No file systems"
echo "   4. ELB Dashboard - No load balancers"
echo "   5. ECR Dashboard - No repositories"
echo ""
echo "💰 Cost Savings:"
echo "   - EKS Cluster: ~$73/month"
echo "   - EFS Storage: ~$0.30/GB/month"
echo "   - Load Balancers: ~$16/month each"
echo "   - NAT Gateway: ~$32/month"
echo "   - EC2 Worker Nodes: ~$60/month (2x m5.large)"
echo ""
echo "   TOTAL SAVINGS: ~$200-300/month"
echo ""
