variable "location" {
  type = string
}

variable "resource_group" {
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

variable "ssh_path" {
  type = string
}

variable "tags"{
  type = map(string)
}

variable "vm_nic"{
  type = string
}