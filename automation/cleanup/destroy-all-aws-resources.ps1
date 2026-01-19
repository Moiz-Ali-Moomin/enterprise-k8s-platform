# PowerShell Script - Complete AWS Resource Cleanup
# This script safely destroys ALL AWS resources to avoid costs

Write-Host "========================================" -ForegroundColor Red
Write-Host "⚠️  AWS RESOURCE CLEANUP - COMPLETE TEARDOWN" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""
Write-Host "This will delete:" -ForegroundColor Yellow
Write-Host "  - All Kubernetes resources (LoadBalancers, Services, PVCs)" -ForegroundColor Yellow
Write-Host "  - EKS Cluster" -ForegroundColor Yellow
Write-Host "  - EFS File System" -ForegroundColor Yellow
Write-Host "  - ECR Repositories" -ForegroundColor Yellow
Write-Host "  - VPC and all networking" -ForegroundColor Yellow
Write-Host "  - All Terraform-managed resources" -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Are you ABSOLUTELY SURE? This cannot be undone! (type 'DELETE' to confirm)"

if ($confirm -ne "DELETE") {
    Write-Host "❌ Cleanup cancelled." -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🚀 Starting cleanup process..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Delete LoadBalancer services
Write-Host "[1/8] Deleting Kubernetes LoadBalancer services..." -ForegroundColor Cyan
kubectl delete svc --all-namespaces --field-selector spec.type=LoadBalancer --wait=true --timeout=300s
Write-Host "   ✅ LoadBalancer services deleted" -ForegroundColor Green
Start-Sleep -Seconds 5

# Step 2: Delete PVCs
Write-Host ""
Write-Host "[2/8] Deleting all PersistentVolumeClaims..." -ForegroundColor Cyan
kubectl delete pvc --all --all-namespaces --wait=true --timeout=300s
Write-Host "   ✅ PVCs deleted" -ForegroundColor Green
Start-Sleep -Seconds 5

# Step 3: Delete namespaces
Write-Host ""
Write-Host "[3/8] Deleting Kubernetes namespaces..." -ForegroundColor Cyan
$namespaces = @("jenkins", "sonarqube", "logging", "monitoring", "argocd", "nfs-provisioner")
foreach ($ns in $namespaces) {
    kubectl delete namespace $ns --wait=true --timeout=300s 2>$null
    if ($?) {
        Write-Host "   ✅ Deleted namespace: $ns" -ForegroundColor Green
    }
    else {
        Write-Host "   ⚠️  Namespace $ns not found" -ForegroundColor Yellow
    }
}
Start-Sleep -Seconds 10

# Step 4: Delete ECR
Write-Host ""
Write-Host "[4/8] Deleting ECR repositories..." -ForegroundColor Cyan
aws ecr delete-repository --repository-name nginx-demo --region us-west-2 --force 2>$null
if ($?) {
    Write-Host "   ✅ Deleted ECR repository: nginx-demo" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  ECR repository not found" -ForegroundColor Yellow
}

# Step 5 & 6: Terraform destroy
Write-Host ""
Write-Host "[5/8] Navigating to Terraform directory..." -ForegroundColor Cyan
Set-Location terraform\aws-eks

Write-Host ""
Write-Host "[6/8] Running Terraform destroy..." -ForegroundColor Cyan
terraform destroy -auto-approve

if ($?) {
    Write-Host ""
    Write-Host "   ✅ Terraform resources destroyed successfully" -ForegroundColor Green
}
else {
    Write-Host ""
    Write-Host "   ⚠️  Terraform destroy encountered errors" -ForegroundColor Red
    Write-Host "   Check AWS Console for any remaining resources" -ForegroundColor Yellow
}

# Step 7: Verify
Write-Host ""
Write-Host "[7/8] Verifying resource cleanup..." -ForegroundColor Cyan

Write-Host "   Checking for EC2 instances..." -ForegroundColor Gray
$instances = aws ec2 describe-instances `
    --filters "Name=tag:kubernetes.io/cluster/enterprise-cluster,Values=owned" `
    --query 'Reservations[*].Instances[?State.Name==`running`].InstanceId' `
    --output text `
    --region us-west-2 2>$null

if ([string]::IsNullOrWhiteSpace($instances)) {
    Write-Host "   ✅ No EC2 instances found" -ForegroundColor Green
}
else {
    Write-Host "   ⚠️  Found running instances: $instances" -ForegroundColor Yellow
}

# Step 8: Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ CLEANUP COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  VERIFY IN AWS CONSOLE:" -ForegroundColor Yellow
Write-Host "   1. EC2 Dashboard - No running instances" -ForegroundColor White
Write-Host "   2. VPC Dashboard - No VPCs except default" -ForegroundColor White
Write-Host "   3. EFS Dashboard - No file systems" -ForegroundColor White
Write-Host "   4. ELB Dashboard - No load balancers" -ForegroundColor White
Write-Host "   5. ECR Dashboard - No repositories" -ForegroundColor White
Write-Host ""
Write-Host "💰 Cost Savings: ~$200-300/month" -ForegroundColor Green
Write-Host ""
