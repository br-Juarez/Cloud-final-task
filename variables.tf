variable "frontend_vm_ip" {
    type = string
}

variable "backend_vm_ip" {
  type = string
}

variable "database_vm_ip"{
    type = string
}

variable "vnet_adress_space"{
    type = string
}

variable "vnet_subnet_prefixes_frontend"{
    type = string
}

variable "vnet_subnet_prefixes_backend"{
    type = string
}

variable "vnet_subnet_prefixes_mysqldb"{
    type = string
}

variable "vnet_bastion"{
    type = string
}