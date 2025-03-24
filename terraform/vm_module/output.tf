output "network_interface_id" {
  value = azurerm_network_interface.main.id
}

output "linux_vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}

output "vm_private_ip" {
  value = azurerm_network_interface.main.private_ip_address
}

output "vm_public_ip"{
  value = azurerm_linux_virtualmachine.main.public_ip_address
}