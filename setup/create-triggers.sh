#!/bin/bash

set -e
# Script to create Cloud Build triggers using Terraform

# --- Configuration ---
PROJECT_ID="${1}"
GITHUB_OWNER="${2}"
REPO_NAME="${3}"
REGION="${4:-us-central1}"
CONNECTION_NAME="${5:-my-github-connection}"

# --- Validation ---
if [[ -z "$PROJECT_ID" || -z "$GITHUB_OWNER" || -z "$REPO_NAME" ]]; then
  echo "Usage: $0 <PROJECT_ID> <GITHUB_OWNER> <REPO_NAME> [REGION] [CONNECTION_NAME]"
  echo "Example: $0 dgzn-terraform dg-ghtest infra"
  exit 1
fi

SERVICE_ACCOUNT_EMAIL="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"

echo "---"
echo "Creating Cloud Build triggers using Terraform"
echo "Project:          $PROJECT_ID"
echo "GitHub Owner:     $GITHUB_OWNER"
echo "Repository:       $REPO_NAME"
echo "Region:           $REGION"
echo "Connection:       $CONNECTION_NAME"
echo "Service Account:  $SERVICE_ACCOUNT_EMAIL"
echo "---"

# Change to setup directory
cd "$(dirname "$0")"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Plan the changes
echo "Planning Terraform changes..."
terraform plan \
  -var="project_id=$PROJECT_ID" \
  -var="github_owner=$GITHUB_OWNER" \
  -var="repo_name=$REPO_NAME" \
  -var="region=$REGION" \
  -var="connection_name=$CONNECTION_NAME" \
  -var="service_account_email=$SERVICE_ACCOUNT_EMAIL"

# Ask for confirmation
echo ""
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "Applying Terraform changes..."
  terraform apply \
    -var="project_id=$PROJECT_ID" \
    -var="github_owner=$GITHUB_OWNER" \
    -var="repo_name=$REPO_NAME" \
    -var="region=$REGION" \
    -var="connection_name=$CONNECTION_NAME" \
    -var="service_account_email=$SERVICE_ACCOUNT_EMAIL" \
    -auto-approve

  echo ""
  echo "✅ Cloud Build triggers created successfully!"
  echo ""
  echo "Created triggers:"
  terraform output -json | jq -r '.main_trigger_name.value, .pr_trigger_name.value'
else
  echo "Aborted."
  exit 1
fi