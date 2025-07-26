# Azure VM Clone from Resource Group A to Resource Group B
# This Terraform configuration clones a VM with OS disk and 2 data disks

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "source_resource_group" {
  description = "Source resource group name (Resource Group A)"
  type        = string
  default     = "rg-source-a"
}

variable "target_resource_group" {
  description = "Target resource group name (Resource Group B)"
  type        = string
  default     = "rg-target-b"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East Asia"
}

variable "source_vm_name" {
  description = "Source VM name in Resource Group A"
  type        = string
  default     = "vm-source"
}

variable "target_vm_name" {
  description = "Target VM name in Resource Group B"
  type        = string
  default     = "vm-cloned"
}

variable "source_os_disk_name" {
  description = "Source OS disk name"
  type        = string
  default     = "vm-source-osdisk"
}

variable "source_data_disk_1_name" {
  description = "Source data disk 1 name"
  type        = string
  default     = "vm-source-datadisk-1"
}

variable "source_data_disk_2_name" {
  description = "Source data disk 2 name"
  type        = string
  default     = "vm-source-datadisk-2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!"
}

# Data sources to get existing resources from Resource Group A
data "azurerm_resource_group" "source" {
  name = var.source_resource_group
}

data "azurerm_managed_disk" "source_os_disk" {
  name                = var.source_os_disk_name
  resource_group_name = var.source_resource_group
}

data "azurerm_managed_disk" "source_data_disk_1" {
  name                = var.source_data_disk_1_name
  resource_group_name = var.source_resource_group
}

data "azurerm_managed_disk" "source_data_disk_2" {
  name                = var.source_data_disk_2_name
  resource_group_name = var.source_resource_group
}

# Target Resource Group B (create if it doesn't exist)
resource "azurerm_resource_group" "target" {
  name     = var.target_resource_group
  location = var.location
}

# Create snapshots of source disks
resource "azurerm_snapshot" "os_disk_snapshot" {
  name                = "${var.target_vm_name}-os-snapshot"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name
  create_option       = "Copy"
  source_resource_id  = data.azurerm_managed_disk.source_os_disk.id

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

resource "azurerm_snapshot" "data_disk_1_snapshot" {
  name                = "${var.target_vm_name}-data1-snapshot"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name
  create_option       = "Copy"
  source_resource_id  = data.azurerm_managed_disk.source_data_disk_1.id

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

resource "azurerm_snapshot" "data_disk_2_snapshot" {
  name                = "${var.target_vm_name}-data2-snapshot"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name
  create_option       = "Copy"
  source_resource_id  = data.azurerm_managed_disk.source_data_disk_2.id

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

# Create new managed disks from snapshots
resource "azurerm_managed_disk" "cloned_os_disk" {
  name                 = "${var.target_vm_name}-osdisk"
  location             = var.location
  resource_group_name  = azurerm_resource_group.target.name
  storage_account_type = data.azurerm_managed_disk.source_os_disk.storage_account_type
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.os_disk_snapshot.id
  disk_size_gb         = data.azurerm_managed_disk.source_os_disk.disk_size_gb

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

resource "azurerm_managed_disk" "cloned_data_disk_1" {
  name                 = "${var.target_vm_name}-datadisk-1"
  location             = var.location
  resource_group_name  = azurerm_resource_group.target.name
  storage_account_type = data.azurerm_managed_disk.source_data_disk_1.storage_account_type
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.data_disk_1_snapshot.id
  disk_size_gb         = data.azurerm_managed_disk.source_data_disk_1.disk_size_gb

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

resource "azurerm_managed_disk" "cloned_data_disk_2" {
  name                 = "${var.target_vm_name}-datadisk-2"
  location             = var.location
  resource_group_name  = azurerm_resource_group.target.name
  storage_account_type = data.azurerm_managed_disk.source_data_disk_2.storage_account_type
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.data_disk_2_snapshot.id
  disk_size_gb         = data.azurerm_managed_disk.source_data_disk_2.disk_size_gb

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }
}

# Create Virtual Network and Subnet
resource "azurerm_virtual_network" "main" {
  name                = "${var.target_vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name

  tags = {
    Environment = "Clone"
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "${var.target_vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.target.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.target_vm_name}-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Clone"
  }
}

# Create Public IP
resource "azurerm_public_ip" "main" {
  name                = "${var.target_vm_name}-pip"
  resource_group_name = azurerm_resource_group.target.name
  location            = var.location
  allocation_method   = "Static"
  sku                = "Standard"

  tags = {
    Environment = "Clone"
  }
}

# Create Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.target_vm_name}-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.target.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  tags = {
    Environment = "Clone"
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.target_vm_name
  resource_group_name = azurerm_resource_group.target.name
  location            = var.location
  size                = "Standard_D4_v5"
  admin_username      = var.admin_username
  
  # Disable password authentication and use SSH keys (recommended)
  disable_password_authentication = false
  admin_password                 = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  # Use the cloned OS disk
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = azurerm_managed_disk.cloned_os_disk.storage_account_type
    disk_size_gb         = azurerm_managed_disk.cloned_os_disk.disk_size_gb
    
    # Attach the existing OS disk
    create_option = "Attach"
  }

  # Rocky Linux 8.10 source image reference (for metadata only when using existing disk)
  source_image_reference {
    publisher = "erockyenterprisesoftwarefoundationinc1653071250513"
    offer     = "rockylinux"
    sku       = "free"
    version   = "8.10.20240528"
  }

  tags = {
    Environment = "Clone"
    Source      = var.source_vm_name
  }

  # Ensure disks are created before VM
  depends_on = [
    azurerm_managed_disk.cloned_os_disk,
    azurerm_managed_disk.cloned_data_disk_1,
    azurerm_managed_disk.cloned_data_disk_2
  ]
}

# Attach Data Disks to VM
resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_1" {
  managed_disk_id    = azurerm_managed_disk.cloned_data_disk_1.id
  virtual_machine_id = azurerm_linux_virtual_machine.main.id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_2" {
  managed_disk_id    = azurerm_managed_disk.cloned_data_disk_2.id
  virtual_machine_id = azurerm_linux_virtual_machine.main.id
  lun                = "2"
  caching            = "ReadWrite"
}

# Outputs
output "cloned_vm_public_ip" {
  description = "Public IP address of the cloned VM"
  value       = azurerm_public_ip.main.ip_address
}

output "cloned_vm_private_ip" {
  description = "Private IP address of the cloned VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "cloned_vm_id" {
  description = "ID of the cloned VM"
  value       = azurerm_linux_virtual_machine.main.id
}

output "resource_group_name" {
  description = "Name of the target resource group"
  value       = azurerm_resource_group.target.name
}
