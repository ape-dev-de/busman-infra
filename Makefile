.DEFAULT_GOAL := start

start:
	terraform apply -var-file .tfvars --target="local_file.kube_config_file"  -auto-approve
	terraform apply -var-file .tfvars  -auto-approve
	
destroy:
	terraform destroy -var-file .tfvars