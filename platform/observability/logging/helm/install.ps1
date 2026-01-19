# Production Observability Stack - Helm Installation (PowerShell)
# Uses production-grade OpenSearch configuration

$ErrorActionPreference = "Stop"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Production Observability Stack - Helm Installation" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$namespace = "logging"

# Check if Helm is installed
try {
    helm version | Out-Null
}
catch {
    Write-Host "❌ Helm is not installed. Please install Helm first." -ForegroundColor Red
    Write-Host "   Visit: https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
    exit 1
}

# Add OpenSearch Helm repository
Write-Host "[1/5] Adding OpenSearch Helm repository..." -ForegroundColor Yellow
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update
Write-Host "✅ OpenSearch Helm repo added" -ForegroundColor Green

# Create namespace
Write-Host ""
Write-Host "[2/5] Creating namespace..." -ForegroundColor Yellow
kubectl create namespace $namespace --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ Namespace created" -ForegroundColor Green

# Install OpenSearch
Write-Host ""
Write-Host "[3/5] Installing OpenSearch cluster..." -ForegroundColor Yellow
Write-Host "   - 3 replicas for High Availability" -ForegroundColor Gray
Write-Host "   - Pod Disruption Budget enabled" -ForegroundColor Gray
Write-Host "   - Topology spread constraints" -ForegroundColor Gray
Write-Host "   - Security enabled" -ForegroundColor Gray
Write-Host ""

helm upgrade --install opensearch opensearch/opensearch `
    --namespace $namespace `
    --values values/opensearch.yaml `
    --wait `
    --timeout 10m

Write-Host "✅ OpenSearch installed" -ForegroundColor Green

# Install OpenSearch Dashboards
Write-Host ""
Write-Host "[4/5] Installing OpenSearch Dashboards..." -ForegroundColor Yellow

helm upgrade --install opensearch-dashboards opensearch/opensearch-dashboards `
    --namespace $namespace `
    --set opensearchHosts="https://opensearch-cluster-master:9200" `
    --set service.type=LoadBalancer `
    --wait `
    --timeout 5m

Write-Host "✅ OpenSearch Dashboards installed" -ForegroundColor Green

# Apply ISM policies
Write-Host ""
Write-Host "[5/5] Applying Index State Management policies..." -ForegroundColor Yellow
kubectl create configmap ism-policies `
    --from-file=configs/policies/ism-policy.json `
    --namespace $namespace `
    --dry-run=client -o yaml | kubectl apply -f -

Write-Host "✅ ISM policies configured" -ForegroundColor Green

# Get service URLs
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "✅ Installation Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Access OpenSearch Dashboards:" -ForegroundColor Yellow
$dashboardUrl = kubectl get svc -n $namespace opensearch-dashboards -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
if ([string]::IsNullOrWhiteSpace($dashboardUrl)) {
    Write-Host "   Waiting for LoadBalancer... Run this command to get URL:" -ForegroundColor Gray
    Write-Host "   kubectl get svc -n $namespace opensearch-dashboards" -ForegroundColor White
}
else {
    Write-Host "   http://$dashboardUrl" -ForegroundColor White
}

Write-Host ""
Write-Host "🔐 Default Credentials:" -ForegroundColor Yellow
Write-Host "   Username: admin" -ForegroundColor White
Write-Host "   Password: admin (change immediately!)" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host "   1. Configure Filebeat/Fluentd to send logs" -ForegroundColor White
Write-Host "   2. Set up index patterns in Dashboards" -ForegroundColor White
Write-Host "   3. Configure ISM policies for index lifecycle" -ForegroundColor White
Write-Host ""
