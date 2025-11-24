# #!/bin/bash

# echo "🧹 Starting complete AWS cleanup..."

# # Delete EKS clusters
# for cluster in $(eksctl get cluster -o json | jq -r '.[].Name'); do
#   echo "Deleting EKS cluster: $cluster"
#   eksctl delete cluster --name $cluster --wait
# done

# # Delete all EC2 instances
# aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`].InstanceId' --output text | \
#   xargs -n 1 aws ec2 terminate-instances --instance-ids

# # Delete all load balancers
# aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn' --output text | \
#   xargs -n 1 aws elbv2 delete-load-balancer --load-balancer-arn

# # Delete all target groups
# aws elbv2 describe-target-groups --query 'TargetGroups[].TargetGroupArn' --output text | \
#   xargs -n 1 aws elbv2 delete-target-group --target-group-arn

# # Delete all S3 buckets (CAREFUL!)
# # aws s3 ls | awk '{print $3}' | xargs -I {} aws s3 rb s3://{} --force

# echo "✅ Cleanup complete!"
