# PowerShell Script: GitHub Secrets Configuration
# This script helps you configure GitHub repository secrets for Jenkins webhook trigger

param(
    [string]$GitHubRepo = "Moiz-Ali-Moomin/enterprise-k8s-platform",
    [string]$GitHubToken = ""
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GitHub Secrets Configuration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$JENKINS_URL = "http://ac07df3aa616f49a28e402fc7a313b61-257689397.us-west-2.elb.amazonaws.com"
$JENKINS_TOKEN = "114275c63975659257e96f354b42d1b944"

# Check if GitHub CLI is installed
$ghInstalled = Get-Command gh -ErrorAction SilentlyContinue

if ($ghInstalled) {
    Write-Host "[Option 1] Using GitHub CLI (gh)" -ForegroundColor Yellow
    Write-Host ""
    
    # Check if authenticated
    $authStatus = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Not authenticated with GitHub CLI" -ForegroundColor Yellow
        Write-Host "Run: gh auth login" -ForegroundColor White
        Write-Host ""
    }
    else {
        Write-Host "✅ GitHub CLI authenticated" -ForegroundColor Green
        Write-Host ""
        
        # Set secrets
        Write-Host "Setting GitHub secrets..." -ForegroundColor Yellow
        
        # JENKINS_URL
        $JENKINS_URL | gh secret set JENKINS_URL --repo $GitHubRepo
        Write-Host "✅ Set secret: JENKINS_URL" -ForegroundColor Green
        
        # JENKINS_TOKEN  
        $JENKINS_TOKEN | gh secret set JENKINS_TOKEN --repo $GitHubRepo
        Write-Host "✅ Set secret: JENKINS_TOKEN" -ForegroundColor Green
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "✅ GitHub Secrets Configured!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
        exit 0
    }
}

# Manual option
Write-Host "[Option 2] Manual Configuration (Copy-Paste)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Go to: https://github.com/$GitHubRepo/settings/secrets/actions/new" -ForegroundColor White
Write-Host ""
Write-Host "Add these secrets:" -ForegroundColor White
Write-Host ""

Write-Host "1️⃣  Secret Name: JENKINS_URL" -ForegroundColor Cyan
Write-Host "   Value:" -ForegroundColor Gray
Write-Host "   $JENKINS_URL" -ForegroundColor White
Write-Host ""

Write-Host "2️⃣  Secret Name: JENKINS_TOKEN" -ForegroundColor Cyan
Write-Host "   Value:" -ForegroundColor Gray
Write-Host "   $JENKINS_TOKEN" -ForegroundColor White
Write-Host ""

# API option
Write-Host "[Option 3] Using GitHub API (Requires Personal Access Token)" -ForegroundColor Yellow
Write-Host ""

if ($GitHubToken -eq "") {
    Write-Host "To use API, run this script with -GitHubToken parameter:" -ForegroundColor Gray
    Write-Host "  .\setup-github-secrets.ps1 -GitHubToken 'your_github_pat'" -ForegroundColor White
    Write-Host ""
    Write-Host "Create a token at: https://github.com/settings/tokens/new" -ForegroundColor Gray
    Write-Host "Required scope: repo" -ForegroundColor Gray
}
else {
    Write-Host "Using GitHub API..." -ForegroundColor Yellow
    
    # Get repository public key (needed for secret encryption)
    try {
        $repoKeyResponse = Invoke-RestMethod -Uri "https://api.github.com/repos/$GitHubRepo/actions/secrets/public-key" `
            -Headers @{
            "Authorization" = "Bearer $GitHubToken"
            "Accept"        = "application/vnd.github+json"
        }
        
        Write-Host "⚠️  GitHub secrets require libsodium encryption" -ForegroundColor Yellow
        Write-Host "   Manual option recommended for Windows" -ForegroundColor Yellow
        Write-Host ""
    }
    catch {
        Write-Host "❌ Error accessing GitHub API: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Next Steps" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "After adding secrets, test the webhook by:" -ForegroundColor White
Write-Host "1. Making a code change to open-source/nginx-demo/" -ForegroundColor White
Write-Host "2. Committing and pushing to main branch" -ForegroundColor White
Write-Host "3. Checking GitHub Actions tab for workflow execution" -ForegroundColor White
Write-Host "4. Verifying Jenkins build was triggered" -ForegroundColor White
Write-Host ""
