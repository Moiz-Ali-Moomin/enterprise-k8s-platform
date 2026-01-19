variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "enterprise-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type for worker nodes"
  type        = string
  default     = "m5.large"
}

variable "kms_key_admin_arn" {
  description = "ARN of the IAM user/role to administer the KMS key"
  type        = string
  default     = null # Will rely on current caller if null
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access Kubernetes API server"
  type        = list(string)
  default     = [] # Force users to specify, empty means private-only access
  
  validation {
    condition     = !contains(var.allowed_cidr_blocks, "0.0.0.0/0")
    error_message = "Public access from 0.0.0.0/0 is not allowed in production. Use specific CIDR blocks or disable public access."
  }
}
