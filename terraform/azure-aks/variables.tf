variable "resource_group_name" {
  description = "Name of the Resource Group"
  type        = string
  default     = "enterprise-k8s-rg"
}

variable "location" {
  description = "Azure Region"
  type        = string
  default     = "East US"
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "enterprise-aks"
}

variable "node_count" {
  description = "Initial node count"
  type        = number
  default     = 3
}

variable "vnet_subnet_id" {
  description = "Subnet ID for the cluster (must exist)"
  type        = string
  # No default, forcing user to provide network
}
