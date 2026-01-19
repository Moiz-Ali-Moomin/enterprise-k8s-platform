# Production Observability Stack - Helm Deployment

This directory contains **production-grade** observability configuration using Helm charts for enterprise deployments.

## 🎯 **Overview**

### **What's Included**:
- ✅ **OpenSearch** (3 replicas, HA, security enabled)
- ✅ **OpenSearch Dashboards** (Kibana alternative)
- ✅ **Index State Management** (automated lifecycle policies)
- ✅ **Pod Disruption Budgets** (protects quorum during updates)
- ✅ **Topology Spread Constraints** (anti-affinity for resilience)
- ✅ **Security Configuration** (RBAC, SSL)

---

## 📂 **Structure**

```
helm/
├── values/
│   ├── opensearch.yaml              # Production OpenSearch configuration
│   ├── dashboards.yaml              # OpenSearch Dashboards config
│   └── logstash.yaml                # Logstash configuration
├── configs/
│   ├── pipeline/
│   │   └── logstash.conf            # Logstash pipeline
│   ├── policies/
│   │   └── ism-policy.json          # Index State Management
│   └── security/
│       └── security-config.yml      # Security settings
├── install.sh                        # Bash installation script
├── install.ps1                       # PowerShell installation script
└── README.md                         # This file
```

---

## 🚀 **Quick Start**

### **Prerequisites**:
1. Kubernetes cluster running (EKS, AKS, GKE, etc.)
2. `kubectl` configured
3. `helm` 3.x installed
4. StorageClass available (e.g., `gp3`, `ebs-sc`, `nfs-client`)

### **Installation**:

**Bash**:
```bash
cd platform/observability/logging/helm
bash install.sh
```

**PowerShell**:
```powershell
cd platform/observability/logging/helm
.\install.ps1
```

---

## ⚙️ **Configuration**

### **Key Settings** (values/opensearch.yaml):

```yaml
opensearch:
  clusterName: "enterprise-logging"
  replicas: 3  # High Availability
  
  resources:
    requests:
      cpu: "1000m"
      memory: "4Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"  # Guaranteed QoS
  
  persistence:
    enabled: true
    size: 100Gi
    storageClass: "gp3"  # Change to your StorageClass
  
  podDisruptionBudget:
    enabled: true
    minAvailable: 2  # Protects quorum
```

### **Customize for Your Environment**:

1. **Storage**: Update `storageClass` in `values/opensearch.yaml`
2. **Resources**: Adjust CPU/memory based on your cluster
3. **Replicas**: Scale up/down based on availability needs
4. **Node Affinity**: Configure `nodeSelector` if needed

---

## 📊 **vs. Basic Manifest Deployment**

| Feature | Manifests (Dev) | Helm (Production) |
|---------|----------------|-------------------|
| **Deployment** | `kubectl apply` | `helm install` |
| **Upgrades** | Manual YAML edits | `helm upgrade` |
| **Rollback** | Git revert | `helm rollback` |
| **HA** | Single node | 3 replicas + PDB |
| **Security** | Disabled | Enabled with RBAC |
| **ISM** | Manual | Automated |
| **Resources** | Basic (500m/1Gi) | Production (1000m/4Gi) |

**Use Helm for production, manifests for development/testing.**

---

## 🔒 **Security**

### **Enabled by Default**:
- ✅ OpenSearch Security Plugin
- ✅ Internal users database
- ✅ Role-based access control (RBAC)
- ✅ TLS/SSL encryption

### **Default Credentials**:
```
Username: admin
Password: admin (CHANGE IMMEDIATELY!)
```

### **Change Admin Password**:
```bash
# After installation
kubectl exec -n logging opensearch-cluster-master-0 -- \
  /usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /usr/share/opensearch/config/opensearch-security/ \
  -icl -nhnv
```

---

## 📈 **Index State Management**

Automated index lifecycle policies are configured via `configs/policies/ism-policy.json`:

- **Hot** (0-7 days): Active indexing
- **Warm** (7-30 days): Read-only, replicas reduced
- **Cold** (30-90 days): Frozen, minimal resources
- **Delete** (90+ days): Auto-deletion

Customize the policy to match your retention requirements.

---

## 🧪 **Verification**

### **Check Installation**:
```bash
# Pods
kubectl get pods -n logging

# Services
kubectl get svc -n logging

# OpenSearch cluster health
kubectl exec -n logging opensearch-cluster-master-0 -- \
  curl -s -XGET "https://localhost:9200/_cluster/health?pretty" -k -u admin:admin
```

### **Access Dashboards**:
```bash
# Get LoadBalancer URL
kubectl get svc -n logging opensearch-dashboards
```

---

## 🔧 **Troubleshooting**

### **Pods not starting**:
- Check storage: `kubectl get pvc -n logging`
- Check resources: `kubectl describe pod -n logging`
- Check logs: `kubectl logs -n logging <pod-name>`

### **Out of memory**:
- Reduce JVM heap in `values/opensearch.yaml`:
  ```yaml
  extraEnvs:
    - name: "OPENSEARCH_JAVA_OPTS"
      value: "-Xms1g -Xmx1g"  # Reduce from 2g
  ```

### **Storage issues**:
- Ensure StorageClass exists: `kubectl get storageclass`
- Check PVC status: `kubectl get pvc -n logging`

---

## 📚 **Additional Resources**

- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [Helm Chart Repository](https://github.com/opensearch-project/helm-charts)
- [ISM Policies Guide](https://opensearch.org/docs/latest/im-plugin/ism/index/)

---

## ✅ **Production Checklist**

Before deploying to production:

- [ ] Updated `storageClass` to match your environment
- [ ] Configured resource requests/limits appropriately
- [ ] Changed default admin password
- [ ] Configured backup/snapshot repository
- [ ] Set up ISM policies for your retention requirements
- [ ] Configured monitoring (Prometheus/Grafana)
- [ ] Tested failover scenarios
- [ ] documented runbook for operations team
