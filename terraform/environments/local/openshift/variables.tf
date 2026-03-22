variable "crc_cpus" {
  description = "CPU count passed to `crc start`."
  type        = number
  default     = 4
}

variable "crc_memory" {
  description = "Memory in MiB passed to `crc start`."
  type        = number
  default     = 12288
}
