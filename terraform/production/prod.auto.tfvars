enable_telemetry              = true
vnet_adress_space             = "20.0.0.0/16"
vnet_subnet_CIDR_frontend = "20.0.1.0/24"
vnet_subnet_CIDR_backend  = "20.0.2.0/24"
vnet_subnet_CIDR_mysqldb  = "20.0.3.0/24"

frontend_vm_ip             = "20.0.1.10"
backend_vm_ip              = "20.0.2.10"
database_firewall_ip_start = "20.0.3.0"
database_firewall_ip_end   = "20.0.3.255"