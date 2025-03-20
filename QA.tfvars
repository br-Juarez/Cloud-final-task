enable_telemetry = false
vnet_adress_space = "10.0.0.0/16"
vnet_subnet_prefixes_frontend = "10.0.1.0/24"
vnet_subnet_prefixes_backend = "10.0.2.0/24"
vnet_subnet_prefixes_mysqldb = "10.0.3.0/24"
vnet_bastion = "10.0.4.0/24"

frontend_vm_ip = "10.0.1.10"
backend_vm_ip = "10.0.2.10"
database_vm_ip = "10.0.3.10"