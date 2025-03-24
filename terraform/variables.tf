variable "enable_telemetry" {
  type = bool
}

variable "frontend_vm_ip_1" {
  type = string
}

variable "frontend_vm_ip_2" {
  type = string
}

variable "backend_vm_ip" {
  type = string
}

variable "database_firewall_ip_start" {
  type = string
}

variable "database_firewall_ip_end" {
  type = string
}

variable "vnet_adress_space" {
  type = string
}

variable "vnet_subnet_CIDR_frontend_1" {
  type = string
}

variable "vnet_subnet_CIDR_frontend_2" {
  type = string
}

variable "vnet_subnet_CIDR_backend" {
  type = string
}

variable "vnet_subnet_CIDR_mysqldb" {
  type = string
}

variable "vnet_subnet_CIDR_bastion" {
  type = string
}

variable "frontend_user" {
  type      = string
  sensitive = true
}

variable "frontend_password" {
  type      = string
  sensitive = true
}

variable "backend_user" {
  type      = string
  sensitive = true
}

variable "backend_password" {
  type      = string
  sensitive = true
}

variable "db_user" {
  type      = string
  sensitive = true
}

variable "db_password" {
  type      = string
  sensitive = true
}