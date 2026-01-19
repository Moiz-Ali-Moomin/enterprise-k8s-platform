#!/bin/bash
# Create Kubernetes Secrets for Jenkins Automation
# This script creates secrets that Jenkins JCasC will use

set -e

echo "========================================"
echo "Jenkins Credentials Secret Setup"
echo "========================================"
echo ""

# AWS Credentials
echo "[1/2] AWS ECR Credentials"
echo "These credentials will be used by Jenkins to push Docker images to ECR"
echo ""
read -p "AWS Access Key ID: " AWS_ACCESS_KEY
read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
echo ""
echo ""

# Create AWS credentials secret
kubectl create secret generic aws-credentials \
  --from-literal=access-key-id="$AWS_ACCESS_KEY" \
  --from-literal=secret-access-key="$AWS_SECRET_KEY" \
  --namespace=jenkins \
  --dry-run=client -o yaml | kubectl apply -f -

echo "✅ AWS credentials secret created"

# SonarQube Token
echo ""
echo "[2/2] SonarQube Token"
echo "Generate a token in SonarQube:"
echo "1. Go to: http://$(kubectl get svc -n sonarqube sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "2. Login: admin / admin"
echo "3. User → My Account → Security → Generate Token"
echo ""
read -p "SonarQube Token (or press Enter to skip): " SONAR_TOKEN

if [ ! -z "$SONAR_TOKEN" ]; then
    kubectl create secret generic sonarqube-token \
      --from-literal=token="$SONAR_TOKEN" \
      --namespace=jenkins \
      --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ SonarQube token secret created"
else
    echo "⚠️  Skipped SonarQube token (you can add it later)"
fi

echo ""
echo "========================================"
echo "✅ Secrets Created!"
echo "========================================"
echo ""
echo "Jenkins will automatically use these credentials via JCasC"
echo ""
echo "Next steps:"
echo "1. Apply Jenkins JCasC configuration:"
echo "   kubectl apply -f kubernetes/platform-services/jenkins/jenkins-casc-config.yaml"
echo ""
echo "2. Restart Jenkins to apply configuration:"
echo "   kubectl rollout restart statefulset/jenkins -n jenkins"
echo ""
