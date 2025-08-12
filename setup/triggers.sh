#!/bin/bash

# Setup script for creating SDK Cloud Build triggers

PROJECT_ID="${1:-my-sdk-project}"
GITHUB_OWNER="${2:-my-sdk-org}"
REPO_NAME="${3:-terraform-github-sdk-module}"

echo "Setting up SDK Cloud Build triggers for project: $PROJECT_ID"

# Create the trigger for the SDK module repository (main branch)
echo "Creating trigger for main branch..."
gcloud builds triggers create github \
  --repo-name="$REPO_NAME" \
  --repo-owner="$GITHUB_OWNER" \
  --branch-pattern=^main$ \
  --build-config=cloudbuild.yaml \
  --name=terraform-sdk-module-auto-apply \
  --description="Auto-apply Terraform changes for SDK repository management module" \
  --service-account="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="$PROJECT_ID"

# Create trigger for pull requests (plan only)
echo "Creating trigger for pull requests..."
gcloud builds triggers create github \
  --repo-name="$REPO_NAME" \
  --repo-owner="$GITHUB_OWNER" \
  --pull-request-pattern=^main$ \
  --build-config=cloudbuild-pr.yaml \
  --name=terraform-sdk-module-pr-plan \
  --description="Terraform plan for SDK repository management pull requests" \
  --service-account="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com" \
  --project="$PROJECT_ID"

echo "Cloud Build triggers setup completed!"