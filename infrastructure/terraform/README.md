# StudySync Infrastructure - Terraform

## Overview
This directory contains Terraform configuration for StudySync infrastructure.

## Structure
```
terraform/
├── provider.tf           # AWS provider configuration
├── variables.tf          # Input variables
├── outputs.tf           # Output values
├── main.tf              # Main infrastructure
├── versions.tf          # Terraform version constraints
├── backend.tf           # Remote state configuration
├── modules/             # Reusable modules
│   ├── vpc/
│   ├── ec2/
│   ├── alb/
│   ├── asg/
│   ├── rds/
│   └── elasticache/
└── environments/        # Environment-specific configs
    ├── dev/
    ├── staging/
    └── prod/
```

## Usage

### Initialize Terraform
```bash
terraform init
```

### Plan Infrastructure Changes
```bash
terraform plan
```

### Apply Infrastructure Changes
```bash
terraform apply
```

### Destroy Infrastructure
```bash
terraform destroy
```

## Environments

### Development
```bash
terraform workspace select dev
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### Staging
```bash
terraform workspace select staging
terraform apply -var-file="environments/staging/terraform.tfvars"
```

### Production
```bash
terraform workspace select prod
terraform apply -var-file="environments/prod/terraform.tfvars"
```
