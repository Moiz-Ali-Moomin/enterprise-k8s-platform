# Technology Stack

This document outlines the comprehensive technology stack used in the Enterprise Kubernetes Platform, categorized by function.

## 🛠️ Infrastructure & Provisioning
*   **Terraform:** The core Infrastructure-as-Code (IaC) tool used to provision resources.
    *   **Providers:** `aws` (EKS, VPC, KMS) and `openstack` (Instances, Networking).
    *   **Backends:** S3 (AWS) and Swift (OpenStack) for remote state management.
*   **Python 3:** Used for custom automation scripting, specifically the `ansible/scripts/generate_inventory.py` bridge between Terraform and Ansible.

## ⚙️ Configuration Management
*   **Ansible:** Used for post-provisioning configuration, node hardening, and bootstrapping functionality.
    *   **Dynamic Inventory:** Custom integration to fetch live IP addresses from Terraform state.

## ⚓ Container & Orchestration
*   **Kubernetes (v1.27):** The container orchestration engine.
*   **Docker:** Used for building container images and running CI runners.
*   **Kind / Kubeadm:** Used for bootstrapping the OpenStack/Bare-metal clusters.

## 🚀 CI/CD & GitOps
*   **GitHub Actions:** Handles Continuous Integration.
    *   **Capabilities:** Unit testing, Docker builds, artifact publishing, and security scanning.
*   **ArgoCD:** Handles Continuous Delivery (GitOps).
    *   **Sync:** Automatically syncs Kubernetes manifests from Git to the cluster.
    *   **Versioning:** Apps are pinned to specific Git tags for stability.

## 🛡️ Security & Networking
*   **Istio:** Service Mesh for traffic management, mTLS, and observability.
*   **Trivy:** Vulnerability scanner for container images (integrated into GitHub Actions).
*   **AWS KMS:** Key Management Service for performing envelope encryption on Kubernetes Secrets.
*   **Cert-Manager:** Automated TLS certificate management using Let's Encrypt / Internal CA.
*   **Network Policies:** Kubernetes-native firewall rules configured with a "Default Deny" posture.

## 📊 Observability
*   **ELK Stack:** Centralized logging solution.
    *   **Elasticsearch:** Log storage and indexing.
    *   **Logstash:** Log processing pipeline.
    *   **Kibana:** Visualization dashboard.
*   **Prometheus:** Time-series database for metrics monitoring.
*   **Grafana:** Dashboarding tool for visualizing Prometheus metrics.
