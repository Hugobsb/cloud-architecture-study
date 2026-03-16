resource "azurerm_container_registry" "acr" {
  name                = var.registry_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = var.aks_kubelet_identity
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}
