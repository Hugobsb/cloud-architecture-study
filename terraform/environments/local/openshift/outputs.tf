output "oc_env_command" {
  description = "Command to configure the shell for the OpenShift Local oc client."
  value       = "eval $(crc oc-env)"
}

output "podman_env_command" {
  description = "Command to configure Podman for the OpenShift Local VM."
  value       = "eval $(crc podman-env)"
}

output "api_url" {
  description = "Default API route host for the OpenShift Local deployment."
  value       = "http://api-cloud-study.apps-crc.testing/job"
}
