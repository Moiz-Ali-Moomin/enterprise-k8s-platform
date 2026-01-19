# Enterprise Kubernetes Platform - Production Deployment Guide (AWS)

This guide details the step-by-step process to deploy the platform to **AWS Elastic Kubernetes Service (EKS)**.

## 1. Prerequisites Check
Ensure the following tools are installed and available in your terminal:
- `terraform` (v1.5.0+)
- `aws` CLI (v2.0+)
- `kubectl` (v1.27+)

## 2. AWS Credentials Setup
Authenticate with AWS. You can use SSO or static credentials.
```powershell
aws configure
# Enter your Access Key ID, Secret Access Key, Region (e.g., us-west-2, us-east-1)
```
Verify identity:
```powershell
aws sts get-caller-identity
```

## 3. Terraform Backend Bootstrap
**Crucial Step**: Terraform needs an S3 bucket to store state and a DynamoDB table for locking. These must exist *before* running Terraform code.

**Run these commands to create them (if they don't exist):**
```powershell
# 1. Create S3 Bucket (Unique Name)
aws s3api create-bucket --bucket enterprise-k8s-platform-tfstate --region us-east-1

# 2. Enable Versioning
aws s3api put-bucket-versioning --bucket enterprise-k8s-platform-tfstate --versioning-configuration Status=Enabled

# 3. Create DynamoDB Table for Locking
aws dynamodb create-table --table-name enterprise-k8s-platform-tflock --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 --region us-east-1
```
*Note: If you use a different region for the bucket, update `terraform/aws-eks/backend.tf` accordingly.*

## 4. Infrastructure Provisioning (Terraform)
Navigate to the AWS module and apply the configuration.

1. **Navigate**:
   ```powershell
   cd terraform/aws-eks
   ```

2. **Initialize**:
   Downloads providers and configures the backend.
   ```powershell
   terraform init
   ```

3. **Plan**:
   Preview changes.
   ```powershell
   terraform plan -out=tfplan
   ```

4. **Apply**:
   Provision the VPC, EKS Cluster, and Node Groups. This will take ~15-20 minutes.
   ```powershell
   terraform apply tfplan
   ```

## 5. Cluster Connectivity
Once Terraform finishes, configure `kubectl` to talk to your new cluster.

```powershell
# Update kubeconfig (replace region if needed)
aws eks update-kubeconfig --region us-west-2 --name enterprise-cluster
```

Verify access:
```powershell
kubectl get nodes
```
*You should see your worker nodes in `Ready` state.*

## 6. GitOps Bootstrap (ArgoCD)
Deploy ArgoCD to manage the platform services and applications.

1. **Install ArgoCD**:
   ```powershell
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **Verify Pods**:
   Wait for ArgoCD pods to be ready.
   ```powershell
   kubectl get pods -n argocd
   ```

3. **Access UI (Port Forward)**:
   ```powershell
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```
   Open `https://localhost:8080`.
   - **Username**: `admin`
   - **Password**: Get existing secret:
     ```powershell
     kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($input))
     ```

4. **Deploy App-of-Apps**:
   Sync the repository.
   
   *Note: Ensure `kubernetes/platform-services/argo-cd/application.yaml` points to your fork/repo URL.*
   
   ```powershell
   kubectl apply -f ../../kubernetes/platform-services/argo-cd/application.yaml
   ```

## 7. Verification
- **ArgoCD**: Check that the 'enterprise-platform' application is syncing.
- **Pods**: Run `kubectl get pods -A` to see all platform components (Istio, Prometheus, etc.) spinning up.
