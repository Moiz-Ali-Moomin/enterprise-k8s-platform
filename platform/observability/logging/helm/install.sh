#!/bin/bash
# Helm-based Production Observability Stack Installation
# Uses production-grade OpenSearch configuration

set -e

echo "=========================================="
echo "Production Observability Stack - Helm Installation"
echo "=========================================="
echo ""

NAMESPACE="logging"

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    echo "   Visit: https://helm.sh/docs/intro/install/"
    exit 1
fi

# Add OpenSearch Helm repository
echo "[1/5] Adding OpenSearch Helm repository..."
helm repo add opensearch https://opensearch-project.github.io/helm-charts/
helm repo update
echo "✅ OpenSearch Helm repo added"

# Create namespace
echo ""
echo "[2/5] Creating namespace..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
echo "✅ Namespace created"

# Install OpenSearch
echo ""
echo "[3/5] Installing OpenSearch cluster..."
echo "   - 3 replicas for High Availability"
echo "   - Pod Disruption Budget enabled"
echo "   - Topology spread constraints"
echo "   - Security enabled"
echo ""

helm upgrade --install opensearch opensearch/opensearch \
  --namespace $NAMESPACE \
  --values values/opensearch.yaml \
  --wait \
  --timeout 10m

echo "✅ OpenSearch installed"

# Install OpenSearch Dashboards (Kibana alternative)
echo ""
echo "[4/5] Installing OpenSearch Dashboards..."

helm upgrade --install opensearch-dashboards opensearch/opensearch-dashboards \
  --namespace $NAMESPACE \
  --set opensearchHosts="https://opensearch-cluster-master:9200" \
  --set service.type=LoadBalancer \
  --wait \
  --timeout 5m

echo "✅ OpenSearch Dashboards installed"

# Apply ISM policies
echo ""
echo "[5/5] Applying Index State Management policies..."
kubectl create configmap ism-policies \
  --from-file=configs/policies/ism-policy.json \
  --namespace $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ ISM policies configured"

# Get service URLs
echo ""
echo "=========================================="
echo "✅ Installation Complete!"
echo "=========================================="
echo ""
echo "📊 Access OpenSearch Dashboards:"
DASHBOARD_URL=$(kubectl get svc -n $NAMESPACE opensearch-dashboards -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
if [ -z "$DASHBOARD_URL" ]; then
    echo "   Waiting for LoadBalancer... Run this command to get URL:"
    echo "   kubectl get svc -n $NAMESPACE opensearch-dashboards"
else
    echo "   http://$DASHBOARD_URL"
fi

echo ""
echo "🔐 Default Credentials:"
echo "   Username: admin"
echo "   Password: (check OpenSearch documentation)"
echo ""
echo "📝 Next Steps:"
echo "   1. Configure Filebeat/Fluentd to send logs"
echo "   2. Set up index patterns in Dashboards"
echo "   3. Configure ISM policies for index lifecycle"
echo ""
