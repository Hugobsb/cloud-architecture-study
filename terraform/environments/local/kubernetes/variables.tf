variable "minikube_profile" {
  description = "Minikube profile name used for the local Kubernetes cluster."
  type        = string
  default     = "cloud-study"
}

variable "minikube_driver" {
  description = "Minikube driver passed to `minikube start`."
  type        = string
  default     = "docker"
}

variable "minikube_kubernetes_version" {
  description = "Kubernetes version passed to `minikube start`."
  type        = string
  default     = "stable"
}

variable "minikube_cpus" {
  description = "CPU count assigned to the Minikube cluster."
  type        = number
  default     = 4
}

variable "minikube_memory" {
  description = "Memory assigned to the Minikube cluster."
  type        = string
  default     = "8192mb"
}

variable "minikube_disk_size" {
  description = "Disk size assigned to the Minikube cluster."
  type        = string
  default     = "30g"
}
