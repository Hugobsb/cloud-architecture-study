variable "cluster_name" {
  type    = string
  default = "cloud-study-cluster"
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group" {
  type    = string
  default = "cloud-study-rg"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "dns_prefix" {
  type    = string
  default = "cloudstudy"
}

variable "registry_name" {
  type    = string
  default = "cloudstudyacr"
}
