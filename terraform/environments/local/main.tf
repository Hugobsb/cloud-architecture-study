terraform {
  required_version = ">= 1.4.0"
}

locals {
  repo_root = abspath("${path.root}/../../..")
}

resource "terraform_data" "local_cluster" {
  input = {
    repo_root                   = local.repo_root
    minikube_profile            = var.minikube_profile
    minikube_driver             = var.minikube_driver
    minikube_kubernetes_version = var.minikube_kubernetes_version
    minikube_cpus               = tostring(var.minikube_cpus)
    minikube_memory             = var.minikube_memory
    minikube_disk_size          = var.minikube_disk_size
  }

  provisioner "local-exec" {
    working_dir = self.input.repo_root
    command     = "./scripts/environments/local/cluster-bootstrap.sh"

    environment = {
      MINIKUBE_PROFILE            = self.input.minikube_profile
      MINIKUBE_DRIVER             = self.input.minikube_driver
      MINIKUBE_KUBERNETES_VERSION = self.input.minikube_kubernetes_version
      MINIKUBE_CPUS               = self.input.minikube_cpus
      MINIKUBE_MEMORY             = self.input.minikube_memory
      MINIKUBE_DISK_SIZE          = self.input.minikube_disk_size
    }
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = self.input.repo_root
    command     = "./scripts/environments/local/cluster-destroy.sh"

    environment = {
      MINIKUBE_PROFILE = self.input.minikube_profile
    }
  }
}
