#!/bin/bash

AWS_REGION="us-east-1"
TTL_HOURS=24

echo "🔍 Checking for expired ECS services..."

# Get current timestamp in seconds
now=$(date +%s)

# Get list of ECS services tagged with TTL and created_at
services=$(aws resourcegroupstaggingapi get-resources \
  --tag-filters Key=ttl,Values=${TTL_HOURS}h \
  --resource-type-filters ecs:service \
  --region $AWS_REGION \
  --query "ResourceTagMappingList[].{ARN:ResourceARN,Tags:Tags}" \
  --output json)

expired_services=0

for row in $(echo "${services}" | jq -c '.[]'); do
  arn=$(echo "$row" | jq -r '.ARN')
  created_at=$(echo "$row" | jq -r '.Tags[] | select(.Key=="created_at") | .Value')

  if [ -z "$created_at" ]; then
    echo "No created_at tag on $arn — skipping"
    continue
  fi

  # Convert to seconds since epoch
  created_ts=$(date -d "$created_at" +%s)
  age_hr=$(( (now - created_ts) / 3600 ))

  if [ "$age_hr" -ge "$TTL_HOURS" ]; then
    echo "🧨 Destroying expired service: $arn (Age: ${age_hr}h)"
    cluster_name=$(echo "$arn" | cut -d'/' -f2)
    service_name=$(echo "$arn" | cut -d'/' -f3)

    # Delete ECS service
    aws ecs update-service --cluster "$cluster_name" --service "$service_name" --desired-count 0 --region $AWS_REGION >/dev/null
    aws ecs delete-service --cluster "$cluster_name" --service "$service_name" --force --region $AWS_REGION >/dev/null

    ((expired_services++))
  else
    echo "Not expired yet: $arn (Age: ${age_hr}h)"
  fi
done

echo "Cleanup complete. Expired services removed: $expired_services"
