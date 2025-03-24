enable_telemetry          = false
vnet_adress_space         = "10.0.0.0/16"
vnet_subnet_CIDR_frontend_1 = "10.0.1.0/24"
vnet_subnet_CIDR_frontend_2 = "10.0.2.0/24"
vnet_subnet_CIDR_backend  = "10.0.3.0/24"
vnet_subnet_CIDR_mysqldb  = "10.0.4.0/24"
vnet_subnet_CIDR_bastion  = "10.0.5.0/26"

frontend_vm_ip_1             = "10.0.1.10"
frontend_vm_ip_2             = "10.0.2.10"
backend_vm_ip              = "10.0.3.10"
database_firewall_ip_start = "10.0.4.0"
database_firewall_ip_end   = "10.0.4.255"