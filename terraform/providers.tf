terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.22"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.3.0"
    }
    modtm = {
      source  = "Azure/modtm"
      version = "0.3.5"
    }
  }

  backend "azurerm" {
  }

}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
