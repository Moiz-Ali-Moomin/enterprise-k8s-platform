#!/bin/bash
# ECR Repository Setup and Jenkinsfile Update Script
# This script creates the ECR repository and updates the Jenkinsfile with your AWS Account ID

set -e

echo "========================================"
echo "AWS ECR Setup for nginx-demo"
echo "========================================"

# Configuration
AWS_REGION="us-west-2"
ECR_REPO_NAME="nginx-demo"
JENKINSFILE_PATH="open-source/nginx-demo/Jenkinsfile"

# Get AWS Account ID
echo "[1/3] Retrieving AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$AWS_ACCOUNT_ID" ]; then
    echo "❌ Error: Could not retrieve AWS Account ID. Make sure AWS CLI is configured."
    exit 1
fi

echo "✅ AWS Account ID: $AWS_ACCOUNT_ID"

# Create ECR Repository
echo ""
echo "[2/3] Creating ECR Repository '$ECR_REPO_NAME'..."

if aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION &>/dev/null; then
    echo "✅ ECR Repository already exists"
    ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)
else
    aws ecr create-repository \
        --repository-name $ECR_REPO_NAME \
        --region $AWS_REGION \
        --image-scanning-configuration scanOnPush=true \
        --encryption-configuration encryptionType=AES256
    
    ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME"
    echo "✅ ECR Repository created successfully"
fi

echo "   Repository URI: $ECR_URI"

# Update Jenkinsfile
echo ""
echo "[3/3] Updating Jenkinsfile with AWS Account ID..."

if [ -f "$JENKINSFILE_PATH" ]; then
    # Backup original
    cp "$JENKINSFILE_PATH" "$JENKINSFILE_PATH.backup"
    
    # Replace YOUR_AWS_ACCOUNT_ID with actual Account ID
    sed -i "s/YOUR_AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" "$JENKINSFILE_PATH"
    
    echo "✅ Jenkinsfile updated successfully"
    echo "   Backup saved to: $JENKINSFILE_PATH.backup"
else
    echo "❌ Error: Jenkinsfile not found at $JENKINSFILE_PATH"
    exit 1
fi

# Summary
echo ""
echo "========================================"
echo "✅ ECR Setup Complete!"
echo "========================================"
echo ""
echo "📝 Summary:"
echo "   ECR Repository: $ECR_URI"
echo "   AWS Account ID: $AWS_ACCOUNT_ID"
echo "   Jenkinsfile: Updated"
echo ""
echo "🔐 Next Steps:"
echo "1. Add AWS credentials to Jenkins:"
echo "   - Go to Jenkins → Manage Jenkins → Credentials"
echo "   - Add 'Username with password' credential"
echo "   - ID: ecr-credentials"
echo "   - Username: <Your AWS Access Key ID>"
echo "   - Password: <Your AWS Secret Access Key>"
echo ""
echo "2. Commit the updated Jenkinsfile:"
echo "   git add $JENKINSFILE_PATH"
echo "   git commit -m 'Update Jenkinsfile with AWS Account ID'"
echo "   git push origin main"
echo ""
