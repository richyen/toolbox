variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
  default     = "richyen-dev-rg"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westus2"
}

variable "vm_size" {
  description = "Azure VM size for the Debian VM."
  type        = string
  default     = "Standard_D4s_v5"
}

variable "admin_username" {
  description = "Admin username for the Debian VM."
  type        = string
  default     = "debian"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key used for VM access."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
