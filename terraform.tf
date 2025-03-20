#EPAM-IaC Terraform: Practical Task 1
terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.116, < 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
  
}

locals {
  #deployment_region = module.regions.regions[random_integer.region_index.result].name
  deployment_region = "eastus" #temporarily pinning on single region
  db_name = "app_mysql"
  enviroment = "${terraform.workspace}"
  additional_tags  = {
    Owner = "Org_Name_" + "${terraform.workspace}"
    Expires = "Never"
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
  name     = module.naming.resource_group.name_unique
  tags     = local.tags
}

# CHECK REQUIREMENTS FOR FREE TIER
module "vm_sku" {
  source  = "Azure/avm-utl-sku-finder/azapi"
  version = "0.3.0"

  location      = azurerm_resource_group.this_rg.location
  cache_results = true

  vm_filters = {
    min_vcpus                      = 2
    max_vcpus                      = 2
    encryption_at_host_supported   = true
    accelerated_networking_enabled = true
    premium_io_supported           = true
    location_zone                  = random_integer.zone_index.result
  }

  depends_on = [random_integer.zone_index]
}

module "natgateway" {
  source  = "Azure/avm-res-network-natgateway/azurerm"
  version = "0.2.1"

  name                = local.enviroment + "_" + module.naming.nat_gateway.name_unique
  enable_telemetry    = true
  location            = azurerm_resource_group.this_rg.location
  resource_group_name = azurerm_resource_group.this_rg.name

  public_ips = {
    public_ip_1 = {
      name = "nat_gw_pip1"
    }
  }
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "=0.8.1"

  resource_group_name = azurerm_resource_group.this_rg.name
  address_space       = [var.vnet_adress_space]
  name                = module.naming.virtual_network.name_unique+"${terraform.workspace}"
  location            = azurerm_resource_group.this_rg.location

  subnets = {
    vm_subnet_1 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}-1"
      address_prefixes = [var.vnet_subnet_prefixes_frontend]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    vm_subnet_2 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}2"
      address_prefixes = [var.vnet_subnet_prefixes_backend]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    vm_subnet_3 = {
      name             = "${module.naming.subnet.name_unique}-${terraform.workspace}3"
      address_prefixes = [var.vnet_subnet_prefixes_mysqldb]
      nat_gateway = {
        id = module.natgateway.resource_id
      }
    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet" + "${terraform.workspace}"
      address_prefixes = ["10.0.4.0/24"]
    }
  }
}

data "azurerm_client_config" "current" {}

##CODE FOR FRONTEND VM
##
module "frontend_vm"{
  source = "./vm_module"
  network_interface_name = module.naming.network_interface.name_unique
  
}