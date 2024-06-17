.DEFAULT_GOAL := start

backend:
	terraform init -reconfigure
	terraform apply --target="module.backend"  -auto-approve
migrate:
	terraform init -migrate-state
start:
	terraform apply -auto-approve
	
destroy:
	terraform destroy -var-file .tfvars