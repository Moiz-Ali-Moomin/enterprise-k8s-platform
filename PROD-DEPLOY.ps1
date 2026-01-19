# PROD-DEPLOY.ps1 - Master One-Click Platform Deployment
# Orchestrates Infrastructure, Connectivity, and GitOps Bootstrapping

Param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("AWS", "Azure", "GCP", "OpenStack", "VMware")]
    [string]$Cloud = "AWS",

    [Parameter(Mandatory = $false)]
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🚀 ENTERPRISE PLATFORM ONE-CLICK DEPLOY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Target Cloud: $Cloud" -ForegroundColor Yellow
Write-Host ""

# 1. Prerequisite Check
Write-Host "[1/5] Checking Prerequisites..." -ForegroundColor White
$tools = @("terraform", "kubectl")
if ($Cloud -eq "AWS") { $tools += "aws" }
if ($Cloud -eq "Azure") { $tools += "az" }
if ($Cloud -eq "GCP") { $tools += "gcloud" }

foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Error: $tool is not installed." -ForegroundColor Red
        exit 1
    }
}
Write-Host "✅ Prerequisites OK." -ForegroundColor Green

# 2. Cloud-Specific Backend Setup (AWS Example)
if ($Cloud -eq "AWS") {
    Write-Host "[2/5] Bootstrapping Terraform Backend (S3/DynamoDB)..." -ForegroundColor White
    $bucketName = "enterprise-k8s-platform-tfstate"
    $tableName = "enterprise-k8s-platform-tflock"

    # Create S3 Bucket if missing
    aws s3api head-bucket --bucket $bucketName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Creating S3 bucket: $bucketName" -ForegroundColor Gray
        aws s3api create-bucket --bucket $bucketName --region $Region
        aws s3api put-bucket-versioning --bucket $bucketName --versioning-configuration Status=Enabled
    }

    # Create DynamoDB table if missing
    aws dynamodb describe-table --table-name $tableName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "   Creating DynamoDB table: $tableName" -ForegroundColor Gray
        aws dynamodb create-table --table-name $tableName `
            --attribute-definitions AttributeName=LockID, AttributeType=S `
            --key-schema AttributeName=LockID, KeyType=HASH `
            --provisioned-throughput ReadCapacityUnits=5, WriteCapacityUnits=5 --region $Region
    }
    Write-Host "✅ Backend Ready." -ForegroundColor Green
}

# 3. Infrastructure Provisioning
Write-Host "[3/5] Provisioning Infrastructure with Terraform..." -ForegroundColor White
$tfPath = "terraform/$( $Cloud.ToLower() )"
if ($Cloud -eq "OpenStack" -or $Cloud -eq "VMware") { $tfPath = "terraform/$( $Cloud.ToLower() )-kind" }

Push-Location $tfPath
Write-Host "   Initializing Terraform..." -ForegroundColor Gray
terraform init -input=false
Write-Host "   Applying Configuration (This may take 15-20 mins)..." -ForegroundColor Gray
terraform apply -auto-approve
Pop-Location
Write-Host "✅ Infrastructure Provisioned." -ForegroundColor Green

# 4. Cluster Connectivity
Write-Host "[4/5] Configuring Cluster Access..." -ForegroundColor White
if ($Cloud -eq "AWS") {
    aws eks update-kubeconfig --region $Region --name enterprise-cluster
}
elseif ($Cloud -eq "Azure") {
    az aks get-credentials --resource-group enterprise-rg --name enterprise-cluster
}
Write-Host "✅ Kubeconfig Updated." -ForegroundColor Green

# 5. GitOps Bootstrap
Write-Host "[5/5] Bootstrapping GitOps (ArgoCD)..." -ForegroundColor White
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host "   Waiting for ArgoCD Server..." -ForegroundColor Gray
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

Write-Host "   Deploying App-of-Apps..." -ForegroundColor Gray
kubectl apply -f kubernetes/platform-services/argo-cd/application.yaml

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🎉 DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ArgoCD UI: http://localhost:8080 (Use port-forward)" -ForegroundColor White
Write-Host "Dashboards: Check Grafana in the monitoring namespace." -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
