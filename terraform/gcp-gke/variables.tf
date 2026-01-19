variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "enterprise-cluster"
}

variable "network" {
  description = "VPC Network name"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnet name"
  type        = string
  default     = "default"
}

variable "ip_range_pods" {
  description = "Secondary range name for Pods"
  type        = string
  default     = "gke-pods"
}

variable "ip_range_services" {
  description = "Secondary range name for Services"
  type        = string
  default     = "gke-services"
}
