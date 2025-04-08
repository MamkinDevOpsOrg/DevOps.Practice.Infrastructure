# Terraform AWS VM

This project demonstrates how to deploy a virtual machine in AWS using Infrastructure as Code (IaC) with Terraform.

## Features

- Uses the AWS provider.
- Includes a separate bootstrap project to create the S3 bucket (`terraform/infra_bootstrap`).
- Uses a remote backend stored in an S3 bucket (`terraform/main_project/backend.tf`).
- Creates an EC2 virtual machine with Terraform (`terraform/main_project/main.tf`).

## Usage

Run the following commands in order:

### 1. Bootstrap: Create S3 bucket for remote state

```bash
cd terraform/infra_bootstrap
terraform init        # Initialize the project and download providers
terraform fmt         # Format Terraform configuration files
terraform validate    # Validate the configuration for syntax and internal consistency
terraform plan        # Preview the deployment plan
terraform apply       # Apply the changes (create S3 bucket)
```

### 2. Deploy infrastructure using remote backend

```bash
cd terraform/main_project
terraform init        # Initialize the project and download providers
terraform fmt         # Format Terraform configuration files
terraform validate    # Validate the configuration for syntax and internal consistency
terraform plan        # Preview the deployment plan
terraform apply       # Apply the changes (create VM)
```

### To destroy the created resources use:

```bash
cd terraform/main_project
./pre_destroy_cleanup.sh    # Delete NAT Gateway and release all unattached EIPs
terraform destroy           # Destroy the created resources
```
