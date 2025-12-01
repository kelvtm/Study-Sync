#!/bin/bash

# ============================================
# Cost Optimization Script
# ============================================
# Shuts down non-production environments after hours
# Can be run as cron job
# ============================================

set -e

ACTION=${1:-status}
ENVIRONMENT=${2:-dev}

echo "🔍 Cost Optimization Tool"
echo ""

case $ACTION in
    shutdown)
        echo "🛑 Shutting down $ENVIRONMENT environment..."
        
        # Get ASG name
        ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
            --query "AutoScalingGroups[?contains(Tags[?Key=='Environment'].Value, '$ENVIRONMENT')].AutoScalingGroupName" \
            --output text)
        
        if [ -z "$ASG_NAME" ]; then
            echo "❌ No ASG found for environment: $ENVIRONMENT"
            exit 1
        fi
        
        # Set desired capacity to 0
        aws autoscaling set-desired-capacity \
            --auto-scaling-group-name "$ASG_NAME" \
            --desired-capacity 0
        
        # Update min size to 0
        aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name "$ASG_NAME" \
            --min-size 0
        
        echo "✅ $ENVIRONMENT environment shut down"
        echo "💰 Saving ~\$0.50/hour (~\$12/day)"
        ;;
        
    startup)
        echo "🚀 Starting up $ENVIRONMENT environment..."
        
        ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
            --query "AutoScalingGroups[?contains(Tags[?Key=='Environment'].Value, '$ENVIRONMENT')].AutoScalingGroupName" \
            --output text)
        
        if [ -z "$ASG_NAME" ]; then
            echo "❌ No ASG found for environment: $ENVIRONMENT"
            exit 1
        fi
        
        # Restore original capacity
        if [ "$ENVIRONMENT" == "dev" ]; then
            MIN=0
            DESIRED=0
        elif [ "$ENVIRONMENT" == "staging" ]; then
            MIN=0
            DESIRED=0
        else
            MIN=1
            DESIRED=1
        fi
        
        aws autoscaling update-auto-scaling-group \
            --auto-scaling-group-name "$ASG_NAME" \
            --min-size $MIN \
            --desired-capacity $DESIRED
        
        echo "✅ $ENVIRONMENT environment started"
        echo "⏳ Wait 3-5 minutes for instances to be ready"
        ;;
        
    status)
        echo "📊 Environment Status:"
        echo ""
        
        for ENV in dev staging prod; do
            ASG_NAME=$(aws autoscaling describe-auto-scaling-groups \
                --query "AutoScalingGroups[?contains(Tags[?Key=='Environment'].Value, '$ENV')].AutoScalingGroupName" \
                --output text)
            
            if [ -z "$ASG_NAME" ]; then
                echo "  $ENV: Not deployed"
                continue
            fi
            
            CAPACITY=$(aws autoscaling describe-auto-scaling-groups \
                --auto-scaling-group-names "$ASG_NAME" \
                --query "AutoScalingGroups[0].DesiredCapacity" \
                --output text)
            
            if [ "$CAPACITY" == "0" ]; then
                echo "  $ENV: 🛑 Shut down (saving money)"
            else
                echo "  $ENV: ✅ Running ($CAPACITY instances)"
            fi
        done
        
        echo ""
        echo "💡 Commands:"
        echo "  Shutdown dev:    $0 shutdown dev"
        echo "  Start dev:       $0 startup dev"
        echo "  Check status:    $0 status"
        ;;
        
    *)
        echo "Usage: $0 [shutdown|startup|status] [environment]"
        exit 1
        ;;
esac