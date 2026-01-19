output "cluster_endpoint" {
  description = "The endpoint for the Kubernetes API server"
  value       = module.aks.cluster_fqdn
}

output "kube_config_raw" {
  description = "Raw kube config to be used by kubectl"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = module.aks.aks_id
}
