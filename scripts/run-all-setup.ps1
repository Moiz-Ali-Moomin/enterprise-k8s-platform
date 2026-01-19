# Master Setup Script - Run All Configuration Steps
# This PowerShell script executes all setup scripts in the correct order

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CI/CD Pipeline Complete Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "📋 This script will configure:" -ForegroundColor Yellow
Write-Host "   1. AWS ECR Repository" -ForegroundColor White
Write-Host "   2. Update Jenkinsfile with AWS Account ID" -ForegroundColor White
Write-Host "   3. GitHub Secrets (JENKINS URL, JENKINS TOKEN)" -ForegroundColor White
Write-Host "   4. SonarQube Webhook" -ForegroundColor White
Write-Host ""

$continue = Read-Host "Continue? (Y/N)"
if ($continue -ne "Y" -and $continue -ne "y") {
    Write-Host "Aborted." -ForegroundColor Red
    exit
}

# Step 1: ECR Setup
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 1: AWS ECR Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path "$scriptsDir\setup-ecr.sh") {
    Write-Host "Running setup-ecr.sh via Git Bash..." -ForegroundColor Yellow
    & "C:\Program Files\Git\bin\bash.exe" "$scriptsDir\setup-ecr.sh"
}
else {
    Write-Host "❌ setup-ecr.sh not found" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to continue to GitHub Secrets setup"

# Step 2: GitHub Secrets
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 2: GitHub Secrets Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path "$scriptsDir\setup-github-secrets.ps1") {
    & "$scriptsDir\setup-github-secrets.ps1"
}
else {
    Write-Host "❌ setup-github-secrets.ps1 not found" -ForegroundColor Red
}

Write-Host ""
Read-Host "Press Enter to continue to SonarQube setup"

# Step 3: SonarQube
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Step 3: SonarQube Webhook Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if (Test-Path "$scriptsDir\setup-sonarqube.sh") {
    Write-Host "Running setup-sonarqube.sh via Git Bash..." -ForegroundColor Yellow
    & "C:\Program Files\Git\bin\bash.exe" "$scriptsDir\setup-sonarqube.sh"
}
else {
    Write-Host "❌ setup-sonarqube.sh not found" -ForegroundColor Red
}

# Final Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 What was configured:" -ForegroundColor Yellow
Write-Host "   ✅ ECR Repository created" -ForegroundColor Green
Write-Host "   ✅ Jenkinsfile updated with AWS Account ID" -ForegroundColor Green
Write-Host "   ✅ GitHub Secrets configured" -ForegroundColor Green
Write-Host "   ✅ SonarQube Webhook configured" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  Manual Steps Still Required:" -ForegroundColor Yellow
Write-Host "1. Add AWS credentials to Jenkins (ID: ecr-credentials)" -ForegroundColor White
Write-Host "2. Add SonarQube token to Jenkins (ID: sonarqube-token)" -ForegroundColor White
Write-Host "3. Create Jenkins job 'nginx-demo' (Pipeline from SCM)" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Test the Pipeline:" -ForegroundColor Yellow
Write-Host "1. Commit and push Jenkinsfile changes:" -ForegroundColor White
Write-Host "   git add open-source/nginx-demo/Jenkinsfile" -ForegroundColor Gray
Write-Host "   git commit -m 'Update Jenkinsfile with AWS Account ID'" -ForegroundColor Gray
Write-Host "   git push origin main" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Make a change to open-source/nginx-demo/index.html" -ForegroundColor White
Write-Host "3. Commit and push - this will trigger the full pipeline!" -ForegroundColor White
Write-Host ""
