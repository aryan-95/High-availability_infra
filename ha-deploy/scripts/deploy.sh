#!/bin/bash
# deploy.sh
# Triggers a near-zero-downtime rolling deployment by refreshing the
# Auto Scaling Group's instances from the latest Launch Template version.
#
# Usage: ./scripts/deploy.sh <asg-name>

set -e

ASG_NAME="${1:-ha-deploy-asg}"

echo "== Starting instance refresh for ASG: $ASG_NAME =="

aws autoscaling start-instance-refresh \
  --auto-scaling-group-name "$ASG_NAME" \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 60}'

echo "== Instance refresh requested. Watching status (Ctrl+C to stop watching) =="

while true; do
  STATUS=$(aws autoscaling describe-instance-refreshes \
    --auto-scaling-group-name "$ASG_NAME" \
    --query 'InstanceRefreshes[0].Status' \
    --output text)

  echo "Refresh status: $STATUS"

  if [[ "$STATUS" == "Successful" || "$STATUS" == "Failed" || "$STATUS" == "Cancelled" ]]; then
    break
  fi

  sleep 15
done

echo "== Deployment finished with status: $STATUS =="
