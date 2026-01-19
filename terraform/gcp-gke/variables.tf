variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "enterprise-cluster"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pod_ip_range_name" {
  description = "Secondary range name for pods"
  type        = string
  default     = "gke-pods"
}

variable "svc_ip_range_name" {
  description = "Secondary range name for services"
  type        = string
  default     = "gke-services"
}
