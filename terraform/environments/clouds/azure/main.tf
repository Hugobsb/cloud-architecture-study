terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "aks" {
  source = "../../../modules/azure/aks"

  cluster_name        = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group
  node_count          = var.node_count
  vm_size             = var.vm_size
  dns_prefix          = var.dns_prefix
}

module "registry" {
  source = "../../../modules/azure/registry"

  registry_name        = var.registry_name
  resource_group_name  = var.resource_group
  location             = var.location
  aks_kubelet_identity = module.aks.kubelet_identity_object_id
}
