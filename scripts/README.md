# CI/CD Pipeline Setup Scripts

This directory contains automation scripts to complete your Jenkins CI/CD pipeline configuration.

## 📁 Scripts Overview

### 1. `setup-ecr.sh` (Bash)
**Purpose**: Create AWS ECR repository and update Jenkinsfile with your AWS Account ID

**What it does**:
- ✅ Retrieves your AWS Account ID
- ✅ Creates ECR repository named `nginx-demo`
- ✅ Enables image scanning on push
- ✅ Updates `Jenkinsfile` with your AWS Account ID (replaces `YOUR_AWS_ACCOUNT_ID`)
- ✅ Creates backup of original Jenkinsfile

**How to run**:
```bash
cd scripts
bash setup-ecr.sh
```

---

### 2. `setup-github-secrets.ps1` (PowerShell)
**Purpose**: Configure GitHub repository secrets for Jenkins webhook trigger

**What it does**:
- ✅ Adds `JENKINS_URL` secret to GitHub
- ✅ Adds `JENKINS_TOKEN` secret to GitHub
- Supports 3 methods:
  1. GitHub CLI (`gh`) - Automatic
  2. Manual copy-paste - Easiest
  3. GitHub API - Advanced

**How to run**:
```powershell
cd scripts
.\setup-github-secrets.ps1
```

---

### 3. `setup-sonarqube.sh` (Bash)
**Purpose**: Configure SonarQube webhook to notify Jenkins

**What it does**:
- ✅ Guides you to generate SonarQube token
- ✅ Creates webhook in SonarQube pointing to Jenkins
- ✅ Provides instructions to add token to Jenkins

**How to run**:
```bash
cd scripts
bash setup-sonarqube.sh
```

---

### 4. `run-all-setup.ps1` (PowerShell) - **MASTER SCRIPT**
**Purpose**: Run all setup scripts in the correct order

**How to run**:
```powershell
cd scripts
.\run-all-setup.ps1
```

---

## 🚀 Quick Start (Recommended)

**Run the master script**:
```powershell
cd c:\Users\Haxor\Desktop\enterprise-k8s-platform\enterprise-k8s-platform\scripts
.\run-all-setup.ps1
```

This will guide you through all configuration steps interactively.
