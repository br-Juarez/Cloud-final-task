#EPAM-IaC Terraform: Practical Task 1

locals {
  #deployment_region = module.regions.regions[random_integer.region_index.result].name
  deployment_region = "eastus" #temporarily pinning on single region
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

module "natgateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.2.0"

  name                = format("%s-%s", module.naming.nat_gateway.name_unique, local.enviroment)
  enable_telemetry    = true
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  public_ips = {
    public_ip_1 = {
      name = "nat_gw_pip1"
    }
  }
  tags = local.tags
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
      address_prefixes = [var.vnet_subnet_CIDR_frontend]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    vm_subnet_2 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}-2"
      address_prefixes = [var.vnet_subnet_CIDR_backend]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    /*
    vm_subnet_3 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}-3"
      address_prefixes = [var.vnet_subnet_prefixes_mysqldb]
      service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    */
  }
  tags = local.tags
}

#data "azurerm_client_config" "current" {}

module "main_frontend_vm" {
  source                 = "./vm_module"
  network_interface_name = module.naming.network_interface.name_unique
  location               = azurerm_resource_group.this_rg.location
  resource_group         = azurerm_resource_group.this_rg.name

  subnet_id      = module.vnet.subnets.vm_subnet_1.resource_id
  private_ip     = var.frontend_vm_ip
  vm_name_prefix = module.naming.linux_virtual_machine.name_unique
  vm_env         = terraform.workspace

  #Credentials for vms and db passed trough env variabless
  username = var.frontend_user
  password = var.frontend_password

  tags = local.tags
}

module "backend_vm" {
  source                 = "./vm_module"
  network_interface_name = module.naming.network_interface.name_unique
  location               = azurerm_resource_group.this_rg.location
  resource_group         = azurerm_resource_group.this_rg.name

  subnet_id      = module.vnet.subnets.vm_subnet_2.resource_id
  private_ip     = var.backend_vm_ip
  vm_name_prefix = module.naming.linux_virtual_machine.name_unique
  vm_env         = terraform.workspace

  #Credentials for vms and db passed trough env variabless
  username = var.backend_user
  password = var.backend_password

  tags = local.tags
}

module "mysql-azure" {
  source                   = "squareops/mysql-azure/azurerm"
  version                  = "1.0.0"
  name                     = "mysql-app-db"
  environment              = lower(terraform.workspace)
  create_vnet              = "false"
  resource_group_location = azurerm_resource_group.this_rg.location
  vnet_resource_group_name = azurerm_resource_group.this_rg.name
  vnet_name                = module.vnet.name        # If vnet creation is set to false, specify the vnet name here.
  vnet_id                  = module.vnet.resource_id # If vnet creation is set to false, specify the vnet id here.
  subnet_cidr              = var.vnet_subnet_CIDR_mysqldb
  administrator_username   = var.db_user
  administrator_password   = var.db_password
  mysql_version            = "8.0.21"
  zones                    = "2"
  storage_size_gb          = "128"
  sku_name                     = "Standard_D2ads_v5"
  backup_retention_days        = "30"
  iops                         = "3000"
  auto_grow_enabled            = true # Auto scale storage
  geo_redundant_backup_enabled = true
  db_collation                 = "utf8_unicode_ci"
  db_charset                   = "utf8"
  diagnostics_enabled          = "true" # For logging and monitoring
  start_ip_address             = var.database_firewall_ip_start
  end_ip_address               = var.database_firewall_ip_end
  maintenance_window = {
    day_of_week  = 3
    start_hour   = 3
    start_minute = 0
  }
  tags = local.tags
}

/*
-------RESOURCES ADDED FOR PRODUCTION ONLY-------
*/

module "backup_frontend_vm" {
  count = local.enviroment == "prod" ? 1 : 0
  source                 = "./vm_module"
  network_interface_name = module.naming.network_interface.name_unique
  location               = azurerm_resource_group.this_rg.location
  resource_group         = azurerm_resource_group.this_rg.name

  subnet_id      = module.vnet.subnets.vm_subnet_1.resource_id
  private_ip     = var.frontend_vm_ip
  vm_name_prefix = module.naming.linux_virtual_machine.name_unique
  vm_env         = terraform.workspace

  #Credentials for vms and db passed trough env variabless
  username = var.frontend_user
  password = var.frontend_password

  tags = local.tags
}