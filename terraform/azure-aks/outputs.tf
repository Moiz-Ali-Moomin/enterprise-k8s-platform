output "cluster_name" {
  description = "AKS cluster name"
  value       = module.aks.aks_name
}

output "cluster_endpoint" {
  description = "AKS API server endpoint"
  value       = module.aks.cluster_fqdn
}

output "kubeconfig_command" {
  description = "Command to configure kubectl for this cluster"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${var.cluster_name}"
}

output "resource_group_name" {
  description = "Azure Resource Group name"
  value       = azurerm_resource_group.aks.name
}

output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.aks.id
}
