#!/bin/bash

AWS_REGION="us-east-1"

read -p "Enter ECS service name (branch name): " BRANCH_NAME

CLUSTER_NAME="ephemeral-cluster"
SERVICE_NAME="ephemeral-service-${BRANCH_NAME}"

echo "WARNING: This will delete service $SERVICE_NAME in $CLUSTER_NAME"

read -p "Are you sure? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Cancelled"
  exit 1
fi

# Scale to zero first
aws ecs update-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --desired-count 0 \
  --region $AWS_REGION

# Delete the service
aws ecs delete-service \
  --cluster $CLUSTER_NAME \
  --service $SERVICE_NAME \
  --force \
  --region $AWS_REGION

echo "Service $SERVICE_NAME deleted."
