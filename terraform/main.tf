#EPAM-IaC Terraform: Practical Task 1
#Linux edit
locals {
  #deployment_region = module.regions.regions[random_integer.region_index.result].name
  deployment_region = "centralus" #temporarily pinning on single region
  db_name           = "app_mysql"
  enviroment        = terraform.workspace
  additional_tags = {
    Owner      = format("%s-%s", "Org_Name_", "${terraform.workspace}")
    Expires    = "Never"
    Department = "CloudOps"
  }
  tags = {
    scenario = "Cloud final task"
  }
  ipconfig_names = ["main-vm-ipconfig", "backup-vm-ipconfig"]
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.4"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.3.0"

  availability_zones_filter = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions_by_name) - 1
  min = 0
}

resource "random_integer" "zone_index" {
  max = length(module.regions.regions_by_name[local.deployment_region].zones)
  min = 1
}

resource "azurerm_resource_group" "this_rg" {
  location = local.deployment_region
  name     = format("%s-%s", module.naming.resource_group.name_unique, local.enviroment)
  tags     = local.tags
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.8.1"

  resource_group_name = azurerm_resource_group.this_rg.name
  address_space       = [var.vnet_adress_space]
  name                = format("%s-%s", module.naming.virtual_network.name_unique, local.enviroment)
  location            = azurerm_resource_group.this_rg.location

  subnets = {
    vm_subnet_1 = {
      name             = "${module.naming.subnet.name_unique}-${local.enviroment}-1"
      address_prefixes = [var.vnet_subnet_CIDR_frontend_1]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    vm_subnet_2 = {
      name             = "${module.naming.subnet.name_unique}-${local.enviroment}-2"
      address_prefixes = [var.vnet_subnet_CIDR_frontend_2]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    vm_subnet_3 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}-3"
      address_prefixes = [var.vnet_subnet_CIDR_backend]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    db_subnet = {
      name              = "${module.naming.subnet.name_unique}-db-${terraform.workspace}"
      address_prefixes  = [var.vnet_subnet_CIDR_mysqldb]
      service_endpoints = ["Microsoft.storage"]
      delegation = [{
        name = "fs"
        service_delegation = {
          name = "Microsoft.DBforMySQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action",
          ]
        }
      }]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.vnet_subnet_CIDR_bastion]
    }
  }
  tags = local.tags
}


module "natgateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.2.0"

  name                = format("NatGateway-%s-%s", module.naming.nat_gateway.name_unique, local.enviroment)
  enable_telemetry    = true
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  tags                = local.tags
}

##NETWORK INTERFACES FOR VMS##
resource "azurerm_network_interface" "vm_main_nic" {
  name                = "vm-main-nic"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  ip_configuration {
    name                          = local.ipconfig_names[0]
    subnet_id                     = module.vnet.subnets.vm_subnet_1.resource_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_vm_ip_1
    primary                       = true
  }
}

resource "azurerm_network_interface" "vm_backup_nic" {
  name                = "vm-backup-nic"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  ip_configuration {
    name                          = local.ipconfig_names[1]
    subnet_id                     = module.vnet.subnets.vm_subnet_2.resource_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.frontend_vm_ip_2
    primary                       = true
  }
}

resource "azurerm_network_interface" "vm_backend_nic" {
  name                = "vm-backend-nic"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  ip_configuration {
    name                          = "backend-vm-ipconfig"
    subnet_id                     = module.vnet.subnets.vm_subnet_3.resource_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend_vm_ip
    primary                       = true
  }
}

resource "azurerm_availability_set" "avset" {
  name = "app-avset"
  location = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 2
  managed = true
}

##NETWORK SECURITY GROUP##
##########################
# Create Network Security Group and rules
resource "azurerm_network_security_group" "appserver" {
  name                = "network_security_group_${local.enviroment}"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  security_rule {
    name                         = "ssh"
    priority                     = 1022
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "22"
    source_address_prefix        = "*"
    destination_address_prefixes = [var.vnet_subnet_CIDR_frontend_1, var.vnet_subnet_CIDR_frontend_2]
  }

  security_rule {
    name                         = "http"
    priority                     = 1080
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Tcp"
    source_port_range            = "*"
    destination_port_range       = "80"
    source_address_prefix        = "*"
    destination_address_prefixes = [var.vnet_subnet_CIDR_frontend_1, var.vnet_subnet_CIDR_frontend_2]
  }
  security_rule {
    access                     = "Allow"
    direction                  = "Inbound"
    name                       = "tls"
    priority                   = 100
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "443"
    destination_address_prefixes = [var.vnet_subnet_CIDR_frontend_1, var.vnet_subnet_CIDR_frontend_2]
  }
}
## ASSOCIATE NSG TO SUBNET ##
resource "azurerm_subnet_network_security_group_association" "nsg_association_subnet_1" {
  subnet_id                 = module.vnet.subnets.vm_subnet_1.resource_id
  network_security_group_id = azurerm_network_security_group.appserver.id
}

resource "azurerm_subnet_network_security_group_association" "nsg_association_subnet_2" {
  subnet_id                 = module.vnet.subnets.vm_subnet_2.resource_id
  network_security_group_id = azurerm_network_security_group.appserver.id
}

##PUBLIC IPS##
##############
resource "azurerm_public_ip" "bastionpip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_public_ip" "natgatewaypip" {
  name                = "natgateway-pip"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_public_ip" "balancerpip" {
  name = "loadbalancer-pip"
  resource_group_name = azurerm_resource_group.this_rg.name
  location = azurerm_resource_group.this_rg.location
  allocation_method = "Static"
  sku = "Standard"
}

data "azurerm_public_ip" "bastionpip" {
  name                = azurerm_public_ip.bastionpip.name
  resource_group_name = azurerm_resource_group.this_rg.name
}

resource "azurerm_bastion_host" "bastion" {
  name                = module.naming.bastion_host.name_unique
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  ip_configuration {
    name                 = "${module.naming.bastion_host.name_unique}-ipconf"
    subnet_id            = module.vnet.subnets["AzureBastionSubnet"].resource_id
    public_ip_address_id = azurerm_public_ip.bastionpip.id
  }
}

## IP association to nat gateway ##
###################################################
resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_ip_association" {
  nat_gateway_id       = module.natgateway.resource_id
  public_ip_address_id = azurerm_public_ip.natgatewaypip.id
}
/*
## Associate the NAT Gateway to subnets ##
##########################################
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_subnet_association_1" {
  subnet_id = module.vnet.subnets.vm_subnet_1.id
  nat_gateway_id = module.natgateway.resource_id
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_subnet_association_2" {
  subnet_id = module.vnet.subnets.vm_subnet_2.id
  nat_gateway_id = module.natgateway.resource_id
}
*/

data "azurerm_client_config" "current" {}

### LOAD BALANCER ###
#####################
resource "azurerm_lb" "appserver_lb" {
  name                = "appserver-lb"
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name
  sku = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.balancerpip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb-backend_address_pool" {
  loadbalancer_id     = azurerm_lb.appserver_lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "lb-" {
  resource_group_name            = azurerm_resource_group.this_rg.name
  loadbalancer_id                = azurerm_lb.appserver_lb.id
  name                           = "HTTPSAccess"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.appserver_lb.frontend_ip_configuration[0].name
}

module "main_frontend_vm1" {
  source         = "./vm_module"
  location       = azurerm_resource_group.this_rg.location
  resource_group = azurerm_resource_group.this_rg.name

  vm_name_prefix = format("%s-%s", module.naming.linux_virtual_machine.name_unique, "main")
  vm_env         = terraform.workspace
  vm_nic         = azurerm_network_interface.vm_main_nic.id

  #Credentials for vms and db passed trough env variabless
  username = var.frontend_user
  ssh_path = "./vm_main.pub"

  tags = local.tags
}

module "backup_frontend_vm2" {
  source         = "./vm_module"
  location       = azurerm_resource_group.this_rg.location
  resource_group = azurerm_resource_group.this_rg.name

  vm_name_prefix = format("%s-%s", module.naming.linux_virtual_machine.name_unique, "backup")
  vm_env         = terraform.workspace
  vm_nic         = azurerm_network_interface.vm_backup_nic.id

  #Credentials for vms and db passed trough env variabless
  username = var.frontend_user
  ssh_path = "./vm_backup.pub"

  tags = local.tags
}

module "backend_vm" {
  source         = "./vm_module"
  location       = azurerm_resource_group.this_rg.location
  resource_group = azurerm_resource_group.this_rg.name

  vm_name_prefix = format("%s-%s", module.naming.linux_virtual_machine.name_unique, "backend")
  vm_env         = terraform.workspace
  vm_nic         = azurerm_network_interface.vm_backend_nic.id

  #Credentials for vms and db passed trough env variabless
  username = var.backend_user
  ssh_path = "./vm_backend.pub"

  tags = local.tags
}

## DATABASE STUFF ##
####################
resource "azurerm_mysql_flexible_server" "mysql_fs" {
  name                   = "app-mysql-fs"
  resource_group_name    = azurerm_resource_group.this_rg.name
  location               = azurerm_resource_group.this_rg.location
  administrator_login    = var.db_user
  administrator_password = var.db_password
  backup_retention_days  = 7
  delegated_subnet_id    = module.vnet.subnets.db_subnet.resource_id
  sku_name               = "B_Standard_B1s"
  zone = "1"
}

resource "azurerm_mysql_flexible_database" "example" {
  name                = "app-mysql-db"
  resource_group_name = azurerm_resource_group.this_rg.name
  server_name         = azurerm_mysql_flexible_server.mysql_fs.name
  charset             = "utf8"
  collation           = "utf8_unicode_ci"
}