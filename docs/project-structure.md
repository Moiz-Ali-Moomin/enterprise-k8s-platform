# Project Structure & File Guide

This document provides a comprehensive map of the `enterprise-k8s-platform` repository, explaining the purpose of every module, directory, and critical file.

## Root Directory
- `README.md`: High-level project overview, quick start guide, and architecture diagrams.

## 📂 `terraform/` (Infrastructure as Code)
Provisions the underlying infrastructure across multiple clouds.

- **`aws-eks/`**: Amazon Web Services module.
    - `main.tf`: Defines VPC, EKS Cluster, Node Groups, and KMS keys.
    - `backend.tf`: Configures S3 bucket for remote state and DynamoDB for locking.
    - `variables.tf`: Configuration inputs (Region, Instance Types, etc.).
- **`openstack-kind/`**: OpenStack module for Private Cloud/On-Prem.
    - `main.tf`: Provisions Compute Instances, Networking, and Security Groups.
    - `outputs.tf`: Exports Master/Worker IPs for Ansible integration.
    - `variables.tf`: Network CIDRs and Image definitions.
- **`azure-aks/`**: Microsoft Azure module.
    - `main.tf`: Provisions resource groups, VNet, and AKS cluster.
- **`gcp-gke/`**: Google Cloud module.
    - `main.tf`: Provisions VPC and GKE Autopilot/Standard clusters.

## 📂 `ansible/` (Configuration Management)
Configures raw VMs into a Kubernetes cluster (for OpenStack/Bare Metal).

- `inventory`: Source of truth for server IP addresses (generated).
- `site.yml`: Master playbook that orchestrates the cluster bootstrap.
- **`scripts/`**:
    - `generate_inventory.py`: **Critical.** Python script that authenticates with Terraform State to generate the dynamic inventory file.
- **`roles/`**: Modular configuration logic (Docker installation, Kubeadm init, CNI setup).

## 📂 `kubernetes/` (Manifests & GitOps)
The "Brain" of the platform. All Kubernetes resources defined here.

- **`platform-services/`**: Core infrastructure workloads.
    - **`argo-cd/`**:
        - `application.yaml`: The App-of-Apps definition that syncs this entire repo.
    - **`service-mesh/`**:
        - `istio-operator.yaml`: Configuration for Istio Pilot and Ingress Gateways.
- **`cluster-addons/`**: Essential plugins.
    - `monitoring/`: Prometheus/Grafana stacks.
    - `ingress/`: NGINX or Istio Ingress Controllers.
    - `cert-manager/`: Certificates and Issuers.
- **`workloads/`**: Sample applications or business logic deployments.

## 📂 `security/` (Policy & compliance)
security-as-Code definitions.

- **`network-policies/`**:
    - `policies.yaml`: Contains the "Default Deny" and namespace isolation rules.
- **`pod-security/`**:
    - `policy.yaml`: Kyverno ClusterPolicies for implementing Pod Security Standards (Restricted).
- **`image-scanning/`**:
    - `scan-job.yaml`: CronJob definition for running daily Trivy vulnerability scans.

## 📂 `storage/` (Persistence)
Storage integration configurations.

- **`csi-drivers/`**:
    - `aws-ebs-csi.yaml`: Helm chart values/manifests for AWS EBS integration.
- **`nfs/`**: Configuration for shared file storage (ReadWriteMany).

## 📂 `ci-cd/` (Automation)
- **`github-actions/`**:
    - `main.yml`: The primary CI pipeline. Runs tests -> Security Scan (Trivy) -> Build -> Push to Registry.

## 📂 `docs/` (Documentation)
- `technology-stack.md`: Detailed list of all tools and versions used.
- `architecture.md`: System design patterns and decision logs.
- `project-structure.md`: (This file) Directory map.

## 📂 `chef/` & `puppet/` (Legacy/Hybrid)
- **`chef/cookbooks/k8s_bootstrap`**: Chef implementation of the node bootstrapping logic (Alternative to Ansible using scripts).
- **`puppet/manifests/site.pp`**: Puppet manifest for ensuring baseline OS configuration compliance (NTP, SSHD config).
