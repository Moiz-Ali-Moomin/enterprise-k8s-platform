output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "cluster_endpoint" {
  description = "Cluster endpoint"
  value       = module.gke.endpoint
}

output "ca_certificate" {
  description = "Cluster root ca certificate"
  value       = module.gke.ca_certificate
  sensitive   = true
}
