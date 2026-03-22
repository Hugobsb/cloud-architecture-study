terraform {
  required_version = ">= 1.4.0"
}

locals {
  repo_root = abspath("${path.root}/../../../..")
}

resource "terraform_data" "local_cluster" {
  input = {
    repo_root  = local.repo_root
    crc_cpus   = tostring(var.crc_cpus)
    crc_memory = tostring(var.crc_memory)
  }

  provisioner "local-exec" {
    working_dir = self.input.repo_root
    command     = "./scripts/environments/openshift-local/cluster-bootstrap.sh"

    environment = {
      CRC_CPUS   = self.input.crc_cpus
      CRC_MEMORY = self.input.crc_memory
    }
  }

  provisioner "local-exec" {
    when        = destroy
    working_dir = self.input.repo_root
    command     = "./scripts/environments/openshift-local/cluster-destroy.sh"
  }
}
