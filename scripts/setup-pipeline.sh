#!/bin/bash
# Jenkins & Pipeline Automation Setup Script
# Run this script to complete the CI/CD pipeline configuration

set -e

echo "========================================="
echo "Jenkins CI/CD Pipeline Setup Automation"
echo "========================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration - Load from environment variables
JENKINS_URL="${JENKINS_URL:-}"
JENKINS_USER="${JENKINS_USER:-admin}"
JENKINS_TOKEN="${JENKINS_TOKEN:-}"
AWS_REGION="${AWS_REGION:-us-west-2}"
ECR_REPO_NAME="${ECR_REPO_NAME:-nginx-demo}"

# Validate required environment variables
if [ -z "$JENKINS_URL" ]; then
    echo -e "${RED}Error: JENKINS_URL environment variable not set${NC}"
    echo "Please set: export JENKINS_URL='http://your-jenkins-url'"
    exit 1
fi

if [ -z "$JENKINS_TOKEN" ]; then
    echo -e "${RED}Error: JENKINS_TOKEN environment variable not set${NC}"
    echo "Please set: export JENKINS_TOKEN='your-jenkins-token'"
    exit 1
fi

# Get AWS Account ID
echo -e "${YELLOW}[1/6] Retrieving AWS Account ID...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo -e "${RED}Error: Could not retrieve AWS Account ID. Make sure AWS CLI is configured.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ AWS Account ID: $AWS_ACCOUNT_ID${NC}"

# Create ECR Repository
echo -e "${YELLOW}[2/6] Creating ECR Repository...${NC}"
if aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION &>/dev/null; then
    echo -e "${GREEN}✓ ECR Repository already exists${NC}"
else
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION
    echo -e "${GREEN}✓ ECR Repository created: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME${NC}"
fi

# Update Jenkinsfile with AWS Account ID
echo -e "${YELLOW}[3/6] Updating Jenkinsfile with AWS Account ID...${NC}"
JENKINSFILE_PATH="open-source/nginx-demo/Jenkinsfile"
if [ -f "$JENKINSFILE_PATH" ]; then
    sed -i "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" "$JENKINSFILE_PATH"
    echo -e "${GREEN}✓ Jenkinsfile updated${NC}"
else
    echo -e "${RED}Warning: Jenkinsfile not found at $JENKINSFILE_PATH${NC}"
fi

# Generate SonarQube Token (requires manual step)
echo -e "${YELLOW}[4/6] SonarQube Token Configuration...${NC}"
echo -e "${YELLOW}Action Required: Generate SonarQube token manually:${NC}"
echo "1. Go to: http://a9b4da4c8571c484dabdedb4b6b76d9e-1716671651.us-west-2.elb.amazonaws.com"
echo "2. Login with: admin / admin"
echo "3. Go to: User → My Account → Security → Generate Token"
echo "4. Name: jenkins"
echo "5. Copy the generated token"
echo ""
read -p "Paste the SonarQube token here (or press Enter to skip): " SONAR_TOKEN

# Add Jenkins Credential for SonarQube (if token provided)
if [ ! -z "$SONAR_TOKEN" ]; then
    echo -e "${YELLOW}Adding SonarQube token to Jenkins...${NC}"
    # Create credential XML
    cat > /tmp/sonar-cred.xml <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>sonarqube-token</id>
  <description>SonarQube Authentication Token</description>
  <username>admin</username>
  <password>$SONAR_TOKEN</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
    
    curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
        --user "$JENKINS_USER:$JENKINS_TOKEN" \
        -H "Content-Type: application/xml" \
        --data-binary @/tmp/sonar-cred.xml
    echo -e "${GREEN}✓ SonarQube token added to Jenkins${NC}"
fi

# Configure AWS Credentials in Jenkins
echo -e "${YELLOW}[5/6] AWS Credentials Configuration...${NC}"
echo -e "${YELLOW}Action Required: Add AWS credentials to Jenkins:${NC}"
echo "You need to add AWS credentials with ID 'ecr-credentials'"
echo ""
echo "Option 1 - Manual (Recommended for security):"
echo "1. Go to: $JENKINS_URL/manage/credentials/store/system/domain/_/newCredentials"
echo "2. Kind: Username with password"
echo "3. ID: ecr-credentials"
echo "4. Username: <Your AWS Access Key ID>"
echo "5. Password: <Your AWS Secret Access Key>"
echo ""
echo "Option 2 - Automated (Enter credentials now):"
read -p "Would you like to add AWS credentials automatically? (y/N): " AUTO_AWS
if [[ "$AUTO_AWS" =~ ^[Yy]$ ]]; then
    read -p "AWS Access Key ID: " AWS_ACCESS_KEY
    read -sp "AWS Secret Access Key: " AWS_SECRET_KEY
    echo ""
    
    cat > /tmp/aws-cred.xml <<EOF
<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>ecr-credentials</id>
  <description>AWS ECR Credentials</description>
  <username>$AWS_ACCESS_KEY</username>
  <password>$AWS_SECRET_KEY</password>
</com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
EOF
    
    curl -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
        --user "$JENKINS_USER:$JENKINS_TOKEN" \
        -H "Content-Type: application/xml" \
        --data-binary @/tmp/aws-cred.xml
    
    rm /tmp/aws-cred.xml
    echo -e "${GREEN}✓ AWS credentials added to Jenkins${NC}"
fi

# GitHub Secrets Configuration
echo -e "${YELLOW}[6/6] GitHub Secrets Configuration...${NC}"
echo -e "${YELLOW}Action Required: Add these secrets to your GitHub repository:${NC}"
echo ""
echo "Go to: https://github.com/Moiz-Ali-Moomin/enterprise-k8s-platform/settings/secrets/actions/new"
echo ""
echo "Add these secrets:"
echo "1. JENKINS_URL"
echo "   Value: $JENKINS_URL"
echo ""
echo "2. JENKINS_TOKEN"
echo "   Value: $JENKINS_TOKEN"
echo ""

# Summary
echo ""
echo "========================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Commit and push your code changes (Jenkinsfile updated)"
echo "2. Add AWS credentials to Jenkins (if not done)"
echo "3. Add GitHub secrets (JENKINS_URL, JENKINS_TOKEN)"
echo "4. Test the pipeline by pushing to the main branch"
echo ""
echo "Pipeline Flow:"
echo "GitHub Push → GitHub Actions → Jenkins Webhook"
echo "  → Docker Build → Trivy Scan → SonarQube → ECR Push → Deploy"
echo ""
