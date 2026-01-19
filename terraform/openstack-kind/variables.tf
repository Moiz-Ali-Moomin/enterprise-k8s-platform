variable "os_cloud_name" {
  description = "The name of the cloud to use from clouds.yaml"
  type        = string
  default     = "openstack"
}

variable "external_network_id" {
  description = "UUID of the external network for the router"
  type        = string
}

variable "keypair_name" {
  description = "Name of the SSH keypair to use for instances"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into nodes"
  type        = string
  default     = "0.0.0.0/0"
  
  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "SSH access from 0.0.0.0/0 is not allowed in production."
  }
}

variable "allowed_api_cidr" {
  description = "CIDR block allowed to access K8s API"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = var.allowed_api_cidr != "0.0.0.0/0"
    error_message = "K8s API access from 0.0.0.0/0 is not allowed in production."
  }
}
