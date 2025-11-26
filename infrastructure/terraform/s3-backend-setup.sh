#!/bin/bash

# ============================================
# Create S3 Bucket for Terraform Remote State
# ============================================
# Run this ONCE before enabling remote backend
# ============================================

set -e

# Configuration
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="studysync-terraform-state-${AWS_ACCOUNT_ID}"
DYNAMODB_TABLE="studysync-terraform-locks"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🪣 Creating Terraform Remote Backend"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "AWS Account: ${AWS_ACCOUNT_ID}"
echo "Region: ${AWS_REGION}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"
echo ""

# ============================================
# Create S3 Bucket
# ============================================

echo "📦 Creating S3 bucket for state files..."

if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
    echo "✅ Bucket already exists: ${BUCKET_NAME}"
else
    aws s3api create-bucket \
        --bucket "${BUCKET_NAME}" \
        --region "${AWS_REGION}"
    
    echo "✅ Bucket created: ${BUCKET_NAME}"
fi

# ============================================
# Enable Versioning
# ============================================

echo ""
echo "🔄 Enabling versioning..."

aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled

echo "✅ Versioning enabled"

# ============================================
# Enable Encryption
# ============================================

echo ""
echo "🔒 Enabling server-side encryption..."

aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                },
                "BucketKeyEnabled": true
            }
        ]
    }'

echo "✅ Encryption enabled"

# ============================================
# Block Public Access
# ============================================

echo ""
echo "🚫 Blocking public access..."

aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "✅ Public access blocked"

# ============================================
# Add Bucket Policy
# ============================================

echo ""
echo "📋 Adding bucket policy..."

BUCKET_POLICY='{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "EnforcedTLS",
        "Effect": "Deny",
        "Principal": "*",
        "Action": "s3:*",
        "Resource": ["arn:aws:s3:::'${BUCKET_NAME}'", "arn:aws:s3:::'${BUCKET_NAME}'/*"],
        "Condition": {"Bool": {"aws:SecureTransport": "false"}}
    }]
}'

aws s3api put-bucket-policy \
    --bucket "${BUCKET_NAME}" \
    --policy "${BUCKET_POLICY}"


echo "✅ Bucket policy added"

# ============================================
# Create DynamoDB Table for State Locking
# ============================================

echo ""
echo "🔐 Creating DynamoDB table for state locking..."

if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" 2>/dev/null; then
    echo "✅ DynamoDB table already exists: ${DYNAMODB_TABLE}"
else
    aws dynamodb create-table \
        --table-name "${DYNAMODB_TABLE}" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "${AWS_REGION}" \
        --tags Key=Project,Value=StudySync Key=ManagedBy,Value=Terraform

    echo "✅ DynamoDB table created: ${DYNAMODB_TABLE}"
    
    echo "⏳ Waiting for table to be active..."
    aws dynamodb wait table-exists \
        --table-name "${DYNAMODB_TABLE}" \
        --region "${AWS_REGION}"
    
    echo "✅ Table is active"
fi

# ============================================
# Summary
# ============================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Remote Backend Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📊 Resources Created:"
echo "  S3 Bucket:       ${BUCKET_NAME}"
echo "  DynamoDB Table:  ${DYNAMODB_TABLE}"
echo ""
echo "🔒 Security Features:"
echo "  ✅ Versioning enabled"
echo "  ✅ Encryption enabled (AES256)"
echo "  ✅ Public access blocked"
echo "  ✅ TLS enforced"
echo "  ✅ State locking enabled"
echo ""
echo "📝 Next Steps:"
echo "  1. Update backend.tf with these values"
echo "  2. Run: terraform init -migrate-state"
echo "  3. Confirm state migration"
echo ""

# Save configuration
cat > backend-config.txt << EOF
# Add this to your backend.tf:

terraform {
  backend "s3" {
    bucket         = "${BUCKET_NAME}"
    key            = "terraform.tfstate"
    region         = "${AWS_REGION}"
    encrypt        = true
    dynamodb_table = "${DYNAMODB_TABLE}"
  }
}
EOF

echo "Configuration saved to: backend-config.txt"
echo ""