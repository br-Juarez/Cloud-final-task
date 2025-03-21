output "network_interface_id" {
  value = azurerm_network_interface.main.id
}

output "linux_vm_id" {
  value = azurerm_linux_virtual_machine.main.id
}