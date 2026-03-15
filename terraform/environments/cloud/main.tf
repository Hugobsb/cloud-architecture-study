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

module "kubernetes" {
  source = "../../modules/kubernetes"

  cluster_name        = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group
  node_count          = var.node_count
  vm_size             = var.vm_size
}

module "registry" {
  source = "../../modules/registry"

  resource_group_name = var.resource_group
  location            = var.location
  aks_kubelet_identity = module.kubernetes.kubelet_identity_object_id
}
