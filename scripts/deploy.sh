#!/bin/bash

# Ask for input
read -p "Enter GitHub repo URL: " REPO_URL
read -p "Enter branch name to deploy: " BRANCH_NAME

# Set variables
REPO_NAME=$(basename "$REPO_URL" .git)
IMAGE_TAG="$BRANCH_NAME"
ECR_REPO_NAME="ephemeral-preview"
AWS_REGION="us-east-1"

# Clone the repo and checkout branch
rm -rf $REPO_NAME
git clone --branch $BRANCH_NAME $REPO_URL
cd $REPO_NAME || { echo "Branch not found!"; exit 1; }

# Create ECR repo if not exists
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Creating ECR repo: $ECR_REPO_NAME"
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION
fi

# Authenticate Docker to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin \
  "$(aws sts get-caller-identity --query 'Account' --output text).dkr.ecr.${AWS_REGION}.amazonaws.com"

# Build Docker image
docker build -t $ECR_REPO_NAME:$IMAGE_TAG .

# Tag and push to ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
ECR_IMAGE_URI="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"

docker tag $ECR_REPO_NAME:$IMAGE_TAG $ECR_IMAGE_URI
docker push $ECR_IMAGE_URI

cd ..

# Run Terraform deployment
cd terraform
terraform init
terraform apply -auto-approve \
  -var="branch_name=$BRANCH_NAME" \
  -var="image_url=$ECR_IMAGE_URI"

# Get output URL
echo -e "\n🎉 Deployment Complete! Access your app at:"
terraform output alb_dns
