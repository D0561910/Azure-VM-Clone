# 定義 Terraform 版本和 Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# 設定 Azure Provider
provider "azurerm" {
  features {}
}

# ==============================================================================
# 變數定義
# 請根據您的環境修改這些變數的值
# ==============================================================================

variable "location" {
  description = "Azure 資源部署的區域"
  type        = string
  default     = "East Asia" # 您可以根據需要更改此值
}

variable "source_resource_group_name" {
  description = "原始快照所在的資源群組名稱 (Resource Group A)"
  type        = string
  default     = "rg-source-snapshots" # 請替換為您實際的資源群組名稱
}

variable "os_disk_snapshot_name" {
  description = "OS Disk 快照的名稱"
  type        = string
  default     = "os-disk-snapshot-existing" # 請替換為您實際的 OS Disk 快照名稱
}

variable "data_disk_snapshot_name_1" {
  description = "第一個 Data Disk 快照的名稱 (對應 LUN 0)"
  type        = string
  default     = "data-disk-snapshot-existing-1" # 請替換為您第一個 Data Disk 快照名稱
}

variable "data_disk_snapshot_name_2" {
  description = "第二個 Data Disk 快照的名稱 (對應 LUN 1)"
  type        = string
  default     = "data-disk-snapshot-existing-2" # 請替換為您第二個 Data Disk 快照名稱
}

variable "target_resource_group_name" {
  description = "新 VM 和磁碟將部署到的資源群組名稱 (Resource Group B)"
  type        = string
  default     = "rg-target-vm" # 您可以根據需要更改此值
}

variable "vm_name" {
  description = "新 VM 的名稱"
  type        = string
  default     = "my-restored-vm" # 您可以根據需要更改此值
}

variable "vm_size" {
  description = "新 VM 的大小 (例如: Standard_DS1_v2)"
  type        = string
  default     = "Standard_DS1_v2" # 您可以根據需要更改此值
}

variable "admin_username" {
  description = "VM 的管理員使用者名稱"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "VM 的管理員密碼 (請使用安全的方式管理，例如 Azure Key Vault)"
  type        = string
  default     = "StrongPassword123!" # 建議使用 SSH Key 或 Azure Key Vault
  sensitive   = true # 將此變數標記為敏感，以避免在 Terraform 輸出中顯示
}

# ==============================================================================
# 資料來源：引用現有的快照
# ==============================================================================

# 引用現有的 OS Disk 快照
data "azurerm_snapshot" "os_snapshot_data" {
  name                = var.os_disk_snapshot_name
  resource_group_name = var.source_resource_group_name
}

# 引用現有的第一個 Data Disk 快照 (LUN 0)
data "azurerm_snapshot" "data_snapshot_data_1" {
  name                = var.data_disk_snapshot_name_1
  resource_group_name = var.source_resource_group_name
}

# 引用現有的第二個 Data Disk 快照 (LUN 1)
data "azurerm_snapshot" "data_snapshot_data_2" {
  name                = var.data_disk_snapshot_name_2
  resource_group_name = var.source_resource_group_name
}

# ==============================================================================
# 資源群組：建立新的目標資源群組 (Resource Group B)
# ==============================================================================

resource "azurerm_resource_group" "rg_target" {
  name     = var.target_resource_group_name
  location = var.location
  tags = {
    environment = "restored-vm"
  }
}

# ==============================================================================
# 受控磁碟：從快照建立新的磁碟
# ==============================================================================

# 從 OS Disk 快照建立新的受控磁碟 (作為新 VM 的 OS Disk)
resource "azurerm_managed_disk" "os_disk_restored" {
  name                 = "${var.vm_name}-os-disk"
  location             = azurerm_resource_group.rg_target.location
  resource_group_name  = azurerm_resource_group.rg_target.name
  storage_account_type = "Standard_LRS" # 可以根據需要選擇 Premium_LRS, Standard_SSD_LRS 等
  create_option        = "Copy"
  source_resource_id   = data.azurerm_snapshot.os_snapshot_data.id
  disk_size_gb         = data.azurerm_snapshot.os_snapshot_data.disk_size_gb # 使用快照的原始大小
  tags = {
    purpose = "restored-os-disk"
  }
}

# 從第一個 Data Disk 快照建立新的受控磁碟 (作為新 VM 的 Data Disk 1 - LUN 0)
resource "azurerm_managed_disk" "data_disk_restored_1" {
  name                 = "${var.vm_name}-data-disk-1"
  location             = azurerm_resource_group.rg_target.location
  resource_group_name  = azurerm_resource_group.rg_target.name
  storage_account_type = "Standard_LRS" # 可以根據需要選擇 Premium_LRS, Standard_SSD_LRS 等
  create_option        = "Copy"
  source_resource_id   = data.azurerm_snapshot.data_snapshot_data_1.id
  disk_size_gb         = data.azurerm_snapshot.data_snapshot_data_1.disk_size_gb # 使用快照的原始大小
  tags = {
    purpose = "restored-data-disk-1"
  }
}

# 從第二個 Data Disk 快照建立新的受控磁碟 (作為新 VM 的 Data Disk 2 - LUN 1)
resource "azurerm_managed_disk" "data_disk_restored_2" {
  name                 = "${var.vm_name}-data-disk-2"
  location             = azurerm_resource_group.rg_target.location
  resource_group_name  = azurerm_resource_group.rg_target.name
  storage_account_type = "Standard_LRS" # 可以根據需要選擇 Premium_LRS, Standard_SSD_LRS 等
  create_option        = "Copy"
  source_resource_id   = data.azurerm_snapshot.data_snapshot_data_2.id
  disk_size_gb         = data.azurerm_snapshot.data_snapshot_data_2.disk_size_gb # 使用快照的原始大小
  tags = {
    purpose = "restored-data-disk-2"
  }
}

# ==============================================================================
# 虛擬機器：建立新的 VM 並掛載磁碟
# ==============================================================================

# 建立一個虛擬網路 (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_target.location
  resource_group_name = azurerm_resource_group.rg_target.name
}

# 建立一個子網路 (Subnet)
resource "azurerm_subnet" "subnet" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.rg_target.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

# 建立一個網路介面卡 (Network Interface)
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.rg_target.location
  resource_group_name = azurerm_resource_group.rg_target.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 建立新的 Linux 虛擬機器
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.rg_target.name
  location                        = azurerm_resource_group.rg_target.location
  size                            = var.vm_size
  admin_username                  = var.admin_username
  admin_password                  = var.admin_password # 建議使用 SSH Key 或 Azure Key Vault
  disable_password_authentication = false # 如果使用 SSH Key，請設定為 true 並提供 ssh_keys 區塊

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  # 設定 OS Disk 為從快照還原的磁碟
  os_disk {
    name                 = azurerm_managed_disk.os_disk_restored.name
    caching              = "ReadWrite"
    storage_account_type = azurerm_managed_disk.os_disk_restored.storage_account_type
    disk_encryption_set_id = null # 如果原始磁碟有加密，這裡可能需要設定
    managed_disk_id      = azurerm_managed_disk.os_disk_restored.id
    create_option        = "Attach" # 這裡必須是 Attach，因為我們是掛載一個已存在的磁碟
  }

  # 設定第一個 Data Disk 為從快照還原的磁碟 (LUN 0)
  storage_data_disk {
    name              = azurerm_managed_disk.data_disk_restored_1.name
    managed_disk_id   = azurerm_managed_disk.data_disk_restored_1.id
    create_option     = "Attach" # 這裡必須是 Attach
    lun               = 0 # 邏輯單元號碼，用於識別磁碟，每個資料磁碟必須是唯一的
    caching           = "ReadWrite"
    disk_size_gb      = azurerm_managed_disk.data_disk_restored_1.disk_size_gb
  }

  # 設定第二個 Data Disk 為從快照還原的磁碟 (LUN 1)
  storage_data_disk {
    name              = azurerm_managed_disk.data_disk_restored_2.name
    managed_disk_id   = azurerm_managed_disk.data_disk_restored_2.id
    create_option     = "Attach" # 這裡必須是 Attach
    lun               = 1 # 邏輯單元號碼，每個資料磁碟必須是唯一的
    caching           = "ReadWrite"
    disk_size_gb      = azurerm_managed_disk.data_disk_restored_2.disk_size_gb
  }

  # 來源映像檔 (Source Image)
  # 由於我們是從快照還原 OS Disk，因此實際的 OS 內容是由 os_disk 區塊中的 managed_disk_id 定義的。
  # 這裡的 source_image_reference 僅用於滿足 Azure ARM 模板的要求，並建議與原始 VM 的 OS 類型保持一致。
  source_image_reference {
    publisher = "RockyEnterpriseSoftwareFoundation"
    offer     = "Rocky-Linux"
    sku       = "8-LVM" # 或 "8"，取決於 Azure Marketplace 中 Rocky Linux 8 的具體 SKU
    version   = "latest" # 可以指定 "8.10.202405150" 或其他特定版本
  }

  tags = {
    environment = "restored-vm"
    source_snapshot_os = var.os_disk_snapshot_name
    source_snapshot_data_1 = var.data_disk_snapshot_name_1
    source_snapshot_data_2 = var.data_disk_snapshot_name_2
  }
}

# ==============================================================================
# 輸出
# ==============================================================================

output "restored_vm_id" {
  description = "還原的 VM ID"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "restored_vm_private_ip" {
  description = "還原的 VM 私有 IP 位址"
  value       = azurerm_network_interface.nic.private_ip_address
}

output "target_resource_group_name" {
  description = "新 VM 所在的資源群組名稱"
  value       = azurerm_resource_group.rg_target.name
}
