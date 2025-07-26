# Variables for Azure VM Clone

variable "source_resource_group" {
  description = "Name of the source Azure Resource Group (where the original VM resides)"
  type        = string
  default     = "rg-source-a" # <--- CHANGE THIS TO YOUR SOURCE RESOURCE GROUP NAME
}

variable "target_resource_group" {
  description = "Name of the target Azure Resource Group (where the cloned VM will be created). It will be created if it doesn't exist."
  type        = string
  default     = "rg-target-b" # <--- CHANGE THIS TO YOUR TARGET RESOURCE GROUP NAME
}

variable "location" {
  description = "Azure region where the cloned VM and resources will be created"
  type        = string
  default     = "East Asia" # <--- CHANGE THIS TO YOUR DESIRED AZURE REGION
}

variable "source_vm_name" {
  description = "Name of the source VM in Resource Group A"
  type        = string
  default     = "vm-source" # <--- CHANGE THIS TO YOUR SOURCE VM NAME
}

variable "target_vm_name" {
  description = "Name for the cloned VM in Resource Group B"
  type        = string
  default     = "vm-cloned" # <--- CHANGE THIS TO YOUR DESIRED CLONED VM NAME
}

variable "source_os_disk_name" {
  description = "Name of the OS disk of the source VM"
  type        = string
  default     = "vm-source-osdisk" # <--- CHANGE THIS TO YOUR SOURCE OS DISK NAME
}

variable "source_data_disk_1_name" {
  description = "Name of the first data disk of the source VM"
  type        = string
  default     = "vm-source-datadisk-1" # <--- CHANGE THIS TO YOUR SOURCE DATA DISK 1 NAME
}

variable "source_data_disk_2_name" {
  description = "Name of the second data disk of the source VM"
  type        = string
  default     = "vm-source-datadisk-2" # <--- CHANGE THIS TO YOUR SOURCE DATA DISK 2 NAME
}

variable "admin_username" {
  description = "Admin username for the cloned VM"
  type        = string
  default     = "azureuser" # <--- CHANGE THIS TO YOUR DESIRED ADMIN USERNAME
}

variable "admin_password" {
  description = "Admin password for the cloned VM. MUST be at least 12 characters long and contain at least one lowercase letter, one uppercase letter, one number, and one special character."
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!" # <--- CHANGE THIS TO A STRONG PASSWORD
}
