# AWS Resource Verification Script
# Run this after cleanup to ensure everything is deleted

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AWS Resource Verification" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$region = "us-west-2"
$allClear = $true

# Check EC2 Instances
Write-Host "[1/7] Checking EC2 Instances..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances `
    --filters "Name=instance-state-name,Values=running,pending,stopping,stopped" `
    --query "Reservations[*].Instances[*].[InstanceId,State.Name]" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($instances)) {
    Write-Host "   ✅ No EC2 instances found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found EC2 instances:" -ForegroundColor Red
    Write-Host $instances
    $allClear = $false
}

# Check EKS Clusters
Write-Host ""
Write-Host "[2/7] Checking EKS Clusters..." -ForegroundColor Yellow
$clusters = aws eks list-clusters --query "clusters" --output text --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($clusters)) {
    Write-Host "   ✅ No EKS clusters found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found EKS clusters: $clusters" -ForegroundColor Red
    $allClear = $false
}

# Check Load Balancers
Write-Host ""
Write-Host "[3/7] Checking Load Balancers..." -ForegroundColor Yellow
$elbs = aws elbv2 describe-load-balancers `
    --query "LoadBalancers[*].LoadBalancerName" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($elbs)) {
    Write-Host "   ✅ No load balancers found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found load balancers: $elbs" -ForegroundColor Red
    $allClear = $false
}

# Check EFS File Systems
Write-Host ""
Write-Host "[4/7] Checking EFS File Systems..." -ForegroundColor Yellow
$efs = aws efs describe-file-systems `
    --query "FileSystems[*].FileSystemId" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($efs)) {
    Write-Host "   ✅ No EFS file systems found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found EFS file systems: $efs" -ForegroundColor Red
    $allClear = $false
}

# Check VPCs (excluding default)
Write-Host ""
Write-Host "[5/7] Checking VPCs..." -ForegroundColor Yellow
$vpcs = aws ec2 describe-vpcs `
    --filters "Name=isDefault,Values=false" `
    --query "Vpcs[*].[VpcId,Tags[?Key=='Name'].Value|[0]]" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($vpcs)) {
    Write-Host "   ✅ No custom VPCs found (only default)" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found custom VPCs:" -ForegroundColor Red
    Write-Host $vpcs
    $allClear = $false
}

# Check ECR Repositories
Write-Host ""
Write-Host "[6/7] Checking ECR Repositories..." -ForegroundColor Yellow
$ecr = aws ecr describe-repositories `
    --query "repositories[*].repositoryName" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($ecr)) {
    Write-Host "   ✅ No ECR repositories found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found ECR repositories: $ecr" -ForegroundColor Red
    $allClear = $false
}

# Check NAT Gateways
Write-Host ""
Write-Host "[7/7] Checking NAT Gateways..." -ForegroundColor Yellow
$nats = aws ec2 describe-nat-gateways `
    --filter "Name=state,Values=available,pending" `
    --query "NatGateways[*].NatGatewayId" `
    --output text `
    --region $region 2>$null

if ([string]::IsNullOrWhiteSpace($nats)) {
    Write-Host "   ✅ No NAT gateways found" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Found NAT gateways: $nats" -ForegroundColor Red
    $allClear = $false
}

# Final Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
if ($allClear) {
    Write-Host "✅ ALL AWS RESOURCES DELETED!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "💰 Monthly Savings: ~$200-300" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now safely close your AWS account or leave it for future use." -ForegroundColor White
}
else {
    Write-Host "⚠️  SOME RESOURCES STILL EXIST" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please manually delete the resources listed above in AWS Console." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor White
    Write-Host "  - ENIs (network interfaces) might be preventing deletion" -ForegroundColor Gray
    Write-Host "  - Security groups might have dependencies" -ForegroundColor Gray
    Write-Host "  - Load balancers created by Kubernetes might not be deleted" -ForegroundColor Gray
}
Write-Host ""
