# Technology Stack

This document outlines the comprehensive technology stack used in the Enterprise Kubernetes Platform, categorized by function.

## 🛠️ Infrastructure & Provisioning (Multi-Cloud)
The platform is designed for a **Hybrid Multi-Cloud** strategy, utilizing Terraform to manage resources across all major providers.

*   **Terraform:** The core Infrastructure-as-Code (IaC) tool.
    *   **Cloud Providers:**
        *   **AWS:** EKS (Elastic Kubernetes Service), VPC, IAM, KMS.
        *   **Azure:** AKS (Azure Kubernetes Service), VNet, Azure Monitor.
        *   **GCP:** GKE (Google Kubernetes Engine), VPC, Cloud IAM.
        *   **OpenStack:** Private Cloud Compute/Networking for on-premise clusters.
    *   **Backends:** Remote state management configured for each provider (S3, GCS, Azure Blob, Swift).
*   **Python 3:** Used for custom automation scripting, specifically the `ansible/scripts/generate_inventory.py` bridge between Terraform and Ansible.

## ⚙️ Configuration Management
The platform supports a flexible configuration layer, allowing teams to use their preferred tools for node hardening and bootstrapping.

*   **Ansible:** Primary tool for agentless configuration and patching.
    *   **Features:** Dynamic Inventory integration, automated node bootstrapping.
*   **Chef:** Supported for environments requiring agent-based state enforcement (Cookbooks).
*   **Puppet:** Supported for large-scale compliance and drift management (Manifests).

## ⚓ Container & Orchestration
*   **Kubernetes (v1.27+):** The unified container orchestration layer across all clouds.
*   **Docker:** Used for building container images and running CI runners.
*   **Kind / Kubeadm:** Used for bootstrapping the OpenStack/Bare-metal clusters.

## 🚀 CI/CD & GitOps
*   **GitHub Actions:** Handles Continuous Integration.
    *   **Capabilities:** Unit testing, Docker builds, artifact publishing, and security scanning.
*   **ArgoCD:** Handles Continuous Delivery (GitOps).
    *   **Sync:** Automatically syncs Kubernetes manifests from Git to the cluster.
    *   **Versioning:** Apps are pinned to specific Git tags for stability.

## 💾 Storage & Persistence
*   **CSI Drivers:** Container Storage Interfaces for dynamic volume provisioning.
    *   **AWS EBS CSI:** Block storage for AWS EKS workloads.
    *   **NFS:** File-based shared storage for ReadWriteMany (RWX) claims on OpenStack/On-Prem.
*   **Data Migration:** Custom scripts for persistent volume migration.

## 🛡️ Security & Compliance
*   **Policy as Code:**
    *   **Kyverno:** Enforces Pod Security Standards (Restricted Profile), requiring non-root users, dropping capabilities, and disallowing privileged containers.
*   **Vulnerability Management:**
    *   **Trivy:**
        *   **CI Scanning:** Scans images during the build pipeline (GitHub Actions).
        *   **Runtime Scanning:** Scheduled CronJobs (`security/image-scanning/scan-job.yaml`) scan running cluster images daily.
*   **Traffic Security:**
    *   **Istio:** mTLS encryption between microservices.
    *   **Network Policies:** Zero-Trust "Default Deny" firewall rules.
*   **Secrets Management:**
    *   **AWS KMS / Azure Key Vault / GCP KMS:** Provider-specific integrations for Secret encryption.

## 📊 Observability
*   **ELK Stack:** Centralized logging solution.
    *   **Elasticsearch:** Log storage and indexing.
    *   **Logstash:** Log processing pipeline.
    *   **Kibana:** Visualization dashboard.
*   **Prometheus:** Time-series database for metrics monitoring.
*   **Grafana:** Dashboarding tool for visualizing Prometheus metrics.
