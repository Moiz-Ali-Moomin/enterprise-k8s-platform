# Migration Runbooks

## 1. Application Migration to Kubernetes
### Prerequisites
- Containerized application
- Health check endpoints (`/health`, `/ready`)
- Resource usage baseline

### Steps
1. Create Namespace
2. Define NetworkPolicy
3. Configure Secrets (KMS/Vault)
4. Deploy to Staging Cluster
5. Perform Load Testing
6. Promote to Production

## 2. Data Migration (EFS/NFS)
### Strategy
- Use `rsync` for initial sync
- Use specialized migration tools for final Cutover
- Verified checksums after copy

## 3. Cloud-to-Cloud Migration
### Steps
1. Provision infrastructure in target cloud
2. Setup peering/interconnect
3. Sync persistent data
4. Deploy platform services via GitOps
5. Global Server Load Balancing (GSLB) weight shift
6. Verify and decommission source cluster
