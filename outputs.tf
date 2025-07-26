# Outputs for Azure VM Clone

output "cloned_vm_public_ip" {
  description = "Public IP address of the cloned VM"
  value       = azurerm_public_ip.main.ip_address
}

output "cloned_vm_private_ip" {
  description = "Private IP address of the cloned VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "cloned_vm_id" {
  description = "Azure resource ID of the cloned VM"
  value       = azurerm_linux_virtual_machine.main.id
}

output "cloned_vm_name" {
  description = "Name of the cloned VM"
  value       = azurerm_linux_virtual_machine.main.name
}

output "resource_group_name" {
  description = "Name of the target resource group where resources were created"
  value       = azurerm_resource_group.target.name
}

output "resource_group_location" {
  description = "Location of the target resource group"
  value       = azurerm_resource_group.target.location
}

output "cloned_os_disk_id" {
  description = "Azure resource ID of the cloned OS disk"
  value       = azurerm_managed_disk.cloned_os_disk.id
}

output "cloned_data_disk_1_id" {
  description = "Azure resource ID of the first cloned data disk"
  value       = azurerm_managed_disk.cloned_data_disk_1.id
}

output "cloned_data_disk_2_id" {
  description = "Azure resource ID of the second cloned data disk"
  value       = azurerm_managed_disk.cloned_data_disk_2.id
}

output "virtual_network_id" {
  description = "Azure resource ID of the created virtual network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "Azure resource ID of the created subnet"
  value       = azurerm_subnet.internal.id
}

output "network_security_group_id" {
  description = "Azure resource ID of the created network security group"
  value       = azurerm_network_security_group.main.id
}

output "ssh_connection_command" {
  description = "SSH command to connect to the cloned VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    source_resource_group = var.source_resource_group
    target_resource_group = azurerm_resource_group.target.name
    source_vm_name       = var.source_vm_name
    cloned_vm_name       = azurerm_linux_virtual_machine.main.name
    vm_size              = azurerm_linux_virtual_machine.main.size
    location             = azurerm_resource_group.target.location
    public_ip            = azurerm_public_ip.main.ip_address
    private_ip           = azurerm_network_interface.main.private_ip_address
  }
}
