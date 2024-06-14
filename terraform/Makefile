.DEFAULT_GOAL := start

backend:
	terraform init -reconfigure
	terraform apply -var-file .tfvars --target="azurerm_storage_container.tfstate"  -auto-approve
migrate:
	terraform init -migrate-state
start:
	terraform apply -var-file .tfvars  -auto-approve
	
destroy:
	terraform destroy -var-file .tfvars