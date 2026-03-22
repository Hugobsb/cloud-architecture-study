output "cluster_name" {
  description = "AKS cluster name."
  value       = module.aks.cluster_name
}

output "resource_group" {
  description = "Azure resource group name."
  value       = module.aks.resource_group
}

output "registry_name" {
  description = "Azure Container Registry name."
  value       = module.registry.registry_name
}

output "registry_login_server" {
  description = "Azure Container Registry login server."
  value       = module.registry.login_server
}
