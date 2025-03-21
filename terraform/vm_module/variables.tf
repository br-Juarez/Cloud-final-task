variable "network_interface_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "private_ip" {
  type = string
}

variable "vm_name_prefix" {
  type = string
}

variable "vm_env" {
  type = string
}

variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "tags"{
  type = map(string)
}
