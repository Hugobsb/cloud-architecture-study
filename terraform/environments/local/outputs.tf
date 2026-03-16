output "minikube_profile" {
  description = "Minikube profile managed by Terraform."
  value       = terraform_data.local_cluster.input.minikube_profile
}

output "docker_env_command" {
  description = "Command to point Docker to the Minikube daemon before building local images."
  value       = "eval $(minikube -p ${terraform_data.local_cluster.input.minikube_profile} docker-env)"
}

output "ingress_ip_command" {
  description = "Command to fetch the Minikube ingress IP."
  value       = "minikube -p ${terraform_data.local_cluster.input.minikube_profile} ip"
}
