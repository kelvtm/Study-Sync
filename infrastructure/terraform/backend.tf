# ============================================
# Terraform Remote Backend Configuration
# ============================================
# Stores state in S3 with DynamoDB locking
# Run s3-backend-setup.sh first!
# ============================================

terraform {
  backend "s3" {
    # S3 bucket for state storage
    # Replace ACCOUNT_ID with your AWS account ID
    bucket = "studysync-terraform-state-118162274891"
    
    # State file path (includes workspace name)
    key = "studysync/terraform.tfstate"
    
    # AWS region
    region = "us-east-1"
    
    # Enable encryption at rest
    encrypt = true
    
    # DynamoDB table for state locking
    dynamodb_table = "studysync-terraform-locks"
    
    # Workspace-specific state files
    workspace_key_prefix = "workspaces"
  }
}

# ============================================
# Alternative: Partial Configuration
# ============================================
# If you want to keep backend config separate:
# 
# 1. Create backend-config.hcl:
#    bucket         = "studysync-terraform-state-123456789012"
#    key            = "studysync/terraform.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "studysync-terraform-locks"
#
# 2. Initialize with:
#    terraform init -backend-config=backend-config.hcl
# ============================================