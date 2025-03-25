resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.vm_name_prefix}-vm-${var.vm_env}"
  resource_group_name             = var.resource_group
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = var.username
  disable_password_authentication = true
  network_interface_ids = [
    var.vm_nic,
  ]

  admin_ssh_key {
    username = var.username
    public_key = file(var.ssh_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  } 

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = var.tags
  
}