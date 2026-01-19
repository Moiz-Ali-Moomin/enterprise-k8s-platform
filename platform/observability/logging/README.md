# Observability Logging Stack

This directory contains **two deployment options** for the logging stack:

## 📂 Structure

```
logging/
├── helm/              # Production (Helm-based, OpenSearch, HA)
│   ├── values/
│   ├── configs/
│   ├── install.sh
│   ├── install.ps1
│   └── README.md
│
└── manifests/         # Development (Raw K8s, Elasticsearch, Simple)
    ├── namespace.yaml
    ├── elasticsearch/
    ├── logstash/
    ├── kibana/
    └── filebeat/
```

## 🎯 Choose Your Deployment

### **Production** → Use `helm/`
- OpenSearch (3 replicas, HA)
- Security enabled
- ISM policies
- Full documentation in `helm/README.md`

### **Development** → Use `manifests/`
- Simple Elasticsearch (single node)
- No security overhead
- Quick deployment
- Lower resource usage

## 🚀 Quick Start

**Production**:
```powershell
cd helm
.\install.ps1
```

**Development**:
```bash
kubectl apply -f manifests/namespace.yaml
kubectl apply -f manifests/elasticsearch/
kubectl apply -f manifests/logstash/
kubectl apply -f manifests/kibana/
kubectl apply -f manifests/filebeat/
```

See individual README files for detailed instructions.
