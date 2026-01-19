provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "aks" {
  name                = "${var.cluster_name}-vnet"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = var.vnet_address_space
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-subnet"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = var.subnet_address_prefixes
}

module "aks" {
  source  = "Azure/aks/azurerm"
  version = "9.1.0" # Updated to latest stable

  resource_group_name = azurerm_resource_group.aks.name
  location            = azurerm_resource_group.aks.location
  cluster_name        = var.cluster_name
  prefix              = "ent-k8s"
  kubernetes_version  = "1.30"

  # Production: Network Configuration
  network_plugin      = "azure"
  network_policy      = "azure"
  vnet_subnet_id      = azurerm_subnet.aks.id
  
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

