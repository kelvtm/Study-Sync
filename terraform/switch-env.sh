#!/bin/bash

# ============================================
# Terraform Workspace Switcher
# ============================================
# Usage: ./switch-env.sh [dev|staging|prod] [plan|apply|destroy]
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check arguments
if [ $# -lt 1 ]; then
    echo -e "${RED}Usage: $0 <environment> [action]${NC}"
    echo ""
    echo "Environments:"
    echo "  dev      - Development environment"
    echo "  staging  - Staging environment"
    echo "  prod     - Production environment"
    echo ""
    echo "Actions (optional):"
    echo "  plan     - Show what will change"
    echo "  apply    - Apply changes"
    echo "  destroy  - Destroy infrastructure"
    echo "  output   - Show outputs"
    echo ""
    echo "Examples:"
    echo "  $0 dev plan"
    echo "  $0 staging apply"
    echo "  $0 prod output"
    exit 1
fi

ENVIRONMENT=$1
ACTION=${2:-plan}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo -e "${RED}❌ Invalid environment: $ENVIRONMENT${NC}"
    echo "Must be: dev, staging, or prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(plan|apply|destroy|output|show)$ ]]; then
    echo -e "${RED}❌ Invalid action: $ACTION${NC}"
    echo "Must be: plan, apply, destroy, output, or show"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🌍 Terraform Environment Manager${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}Environment:${NC} $ENVIRONMENT"
echo -e "${GREEN}Action:${NC}      $ACTION"
echo ""

# Confirmation for production
if [ "$ENVIRONMENT" == "prod" ] && [ "$ACTION" != "plan" ] && [ "$ACTION" != "output" ]; then
    echo -e "${YELLOW}⚠️  WARNING: You are about to modify PRODUCTION!${NC}"
    echo -e "${YELLOW}This action cannot be undone easily.${NC}"
    echo ""
    read -p "Type 'yes' to continue: " -r
    echo ""
    if [[ ! $REPLY == "yes" ]]; then
        echo -e "${RED}❌ Aborted${NC}"
        exit 1
    fi
fi

# Check if workspace exists
WORKSPACE_EXISTS=$(terraform workspace list | grep -w "$ENVIRONMENT" || true)

if [ -z "$WORKSPACE_EXISTS" ]; then
    echo -e "${YELLOW}📝 Creating workspace: $ENVIRONMENT${NC}"
    terraform workspace new "$ENVIRONMENT"
else
    echo -e "${GREEN}✅ Switching to workspace: $ENVIRONMENT${NC}"
    terraform workspace select "$ENVIRONMENT"
fi

echo ""

# Show current workspace
CURRENT=$(terraform workspace show)
echo -e "${GREEN}📍 Current workspace: $CURRENT${NC}"
echo ""

# Variable file
TFVARS="environments/${ENVIRONMENT}.tfvars"

if [ ! -f "$TFVARS" ]; then
    echo -e "${RED}❌ Variable file not found: $TFVARS${NC}"
    exit 1
fi

echo -e "${GREEN}📄 Using variables: $TFVARS${NC}"
echo ""

# Execute action
case $ACTION in
    plan)
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}📋 Planning changes for $ENVIRONMENT${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        terraform plan -var-file="$TFVARS" -out="${ENVIRONMENT}.tfplan"
        echo ""
        echo -e "${GREEN}✅ Plan saved to: ${ENVIRONMENT}.tfplan${NC}"
        echo -e "${YELLOW}💡 Review the plan above before applying${NC}"
        echo -e "${YELLOW}💡 Run: $0 $ENVIRONMENT apply${NC}"
        ;;
        
    apply)
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}🚀 Applying changes to $ENVIRONMENT${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # Check if plan exists
        if [ -f "${ENVIRONMENT}.tfplan" ]; then
            echo -e "${GREEN}Using existing plan: ${ENVIRONMENT}.tfplan${NC}"
            terraform apply "${ENVIRONMENT}.tfplan"
            rm "${ENVIRONMENT}.tfplan"
        else
            terraform apply -var-file="$TFVARS"
        fi
        
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ Changes applied to $ENVIRONMENT${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        ;;
        
    destroy)
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}🗑️  Destroying $ENVIRONMENT infrastructure${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  This will DELETE all resources!${NC}"
        echo ""
        
        terraform destroy -var-file="$TFVARS"
        
        echo ""
        echo -e "${GREEN}✅ $ENVIRONMENT infrastructure destroyed${NC}"
        ;;
        
    output)
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}📊 Outputs for $ENVIRONMENT${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        terraform output
        ;;
        
    show)
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}📋 Current state for $ENVIRONMENT${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        terraform show
        ;;
esac

echo ""