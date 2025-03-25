output "bastion_public_ip" {
  value = data.azurerm_public_ip.bastionpip.ip_address
}

output "main_vm_public_ip" {
  value = module.main_frontend_vm1.vm_public_ip
}

output "backup_vm_public_ip" {
  value = module.backup_frontend_vm2.vm_public_ip
}

output "backend_vm_public_ip" {
  value = module.backend_vm.vm_public_ip
}
/*
output "mysqldb_public_ip" {
  
}
*/