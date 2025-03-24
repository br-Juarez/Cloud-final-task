output "bastion_public_ip"{
  value = data.azurerm_public_ip.bastionpip.ip_address
}