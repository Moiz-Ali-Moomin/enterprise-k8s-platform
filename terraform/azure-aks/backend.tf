terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "enterprisek8stfstate"
    container_name       = "tfstate"
    key                  = "azure-aks.terraform.tfstate"
  }
}
