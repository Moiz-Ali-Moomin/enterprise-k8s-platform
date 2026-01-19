#!/bin/bash
# SonarQube Webhook Configuration Script
# This script configures the webhook in SonarQube to notify Jenkins

set -e

echo "========================================"
echo "SonarQube Webhook Configuration"
echo "========================================"

# Configuration
SONARQUBE_URL="http://a9b4da4c8571c484dabdedb4b6b76d9e-1716671651.us-west-2.elb.amazonaws.com"
JENKINS_WEBHOOK="http://jenkins.jenkins:8080/sonarqube-webhook/"
SONARQUBE_USER="admin"
SONARQUBE_PASS="admin"

echo ""
echo "📝 Configuration:"
echo "   SonarQube URL: $SONARQUBE_URL"
echo "   Jenkins Webhook: $JENKINS_WEBHOOK"
echo ""

# Step 1: Generate SonarQube Token
echo "[1/3] Generate SonarQube Token for Jenkins Integration"
echo ""
echo "⚠️  Manual Step Required:"
echo "1. Go to: $SONARQUBE_URL"
echo "2. Login with: admin / admin"
echo "3. Go to: User Icon (top-right) → My Account → Security"
echo "4. Under 'Generate Tokens':"
echo "   - Name: jenkins"
echo "   - Type: User Token"
echo "   - Expires: Never"
echo "5. Click 'Generate' and copy the token"
echo ""
read -p "Paste the SonarQube token here: " SONAR_TOKEN

if [ -z "$SONAR_TOKEN" ]; then
    echo "❌ No token provided. Exiting."
    exit 1
fi

echo "✅ Token received"

# Step 2: Create Webhook in SonarQube
echo ""
echo "[2/3] Creating Webhook in SonarQube..."

WEBHOOK_NAME="Jenkins"

# Check if webhook already exists
EXISTING_WEBHOOK=$(curl -s -u "$SONARQUBE_USER:$SONARQUBE_PASS" \
    "$SONARQUBE_URL/api/webhooks/list" | grep -c "\"name\":\"$WEBHOOK_NAME\"" || true)

if [ "$EXISTING_WEBHOOK" -gt 0 ]; then
    echo "✅ Webhook '$WEBHOOK_NAME' already exists"
else
    # Create webhook
    curl -X POST -u "$SONARQUBE_USER:$SONARQUBE_PASS" \
        "$SONARQUBE_URL/api/webhooks/create" \
        -d "name=$WEBHOOK_NAME" \
        -d "url=$JENKINS_WEBHOOK"
    
    echo ""
    echo "✅ Webhook created successfully"
fi

# Step 3: Display Jenkins Configuration Instructions
echo ""
echo "[3/3] Jenkins Configuration Instructions"
echo ""
echo "Add SonarQube token to Jenkins:"
echo "1. Go to: $JENKINS_URL/manage/configure"
echo "2. Scroll to 'SonarQube servers' section"
echo "3. Click 'Add SonarQube'"
echo "   - Name: SonarQube"
echo "   - Server URL: http://sonarqube.sonarqube:9000"
echo "   - Server authentication token:"
echo "     → Click 'Add' → Jenkins → 'Secret text'"
echo "     → Secret: $SONAR_TOKEN"
echo "     → ID: sonarqube-token"
echo "     → Description: SonarQube Authentication Token"
echo "4. Select the token from dropdown"
echo "5. Click 'Save'"
echo ""

# Summary
echo "========================================"
echo "✅ Configuration Complete!"
echo "========================================"
echo ""
echo "📝 Summary:"
echo "   ✅ SonarQube webhook configured"
echo "   ✅ SonarQube token generated"
echo "   ⚠️  Manually add token to Jenkins (see instructions above)"
echo ""
echo "🔗 Webhook Flow:"
echo "   SonarQube Analysis Complete → Webhook → Jenkins"
echo ""
