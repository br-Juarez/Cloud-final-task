# Instructions
### ALWAYS run the .sp1 local file with the env vars for the credentials
### use sources comand on linux

## On every env change
terraform init --backend-config=<specific env .conf file> [-reconfigure] if necessary

## Always add the .tfvar file
terraform plan -var-file="<env .tfvar file>"

terraform apply -var-file="env .tfvar file"