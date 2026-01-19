provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "7.3.1"

  resource_group_name = azurerm_resource_group.aks.name
  location            = var.location
  cluster_name        = var.cluster_name
  prefix              = "ent-k8s"
  kubernetes_version  = "1.27"

  # Production: Network Configuration
  network_plugin      = "azure"
  network_policy      = "azure"
  vnet_subnet_id      = var.vnet_subnet_id # Assuming passed variable for existing VNet
  
  # Production: RBAC & AAD Integration
  role_based_access_control_enabled = true
  rbac_aad                          = true
  
  # Production: Managed Identity
  identity_type = "SystemAssigned"

  agents_count = var.node_count
  agents_size  = "Standard_D4s_v3" # Production size
  agents_type  = "VirtualMachineScaleSets"
  
  # Production: Availability Zones
  agents_availability_zones = ["1", "2", "3"]
  
  enable_auto_scaling = true
  agents_min_count    = 3
  agents_max_count    = 10

  # Production: Monitoring
  log_analytics_workspace_enabled = true
  
  tags = {
    Environment = "Production"
    Project     = "Enterprise Kubernetes Platform"
  }
}
