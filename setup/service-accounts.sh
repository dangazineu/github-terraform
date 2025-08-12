#!/bin/bash

# Setup script for creating SDK service accounts

set -euo pipefail

PROJECT_ID="${1}"
if [[ -z "$PROJECT_ID" ]]; then
    echo "Usage: $0 <project_id>"
    echo "Example: $0 my-sdk-project"
    exit 1
fi

echo "Setting up SDK service accounts for project: $PROJECT_ID"

# Verify project exists and is accessible
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    echo "ERROR: Project '$PROJECT_ID' not found or not accessible"
    echo "Make sure:"
    echo "1. Project exists: gcloud projects list"
    echo "2. You have access: gcloud config set project $PROJECT_ID"
    echo "3. Required APIs are enabled: gcloud services list --enabled"
    exit 1
fi

# Verify required APIs are enabled
echo "Checking required APIs..."
REQUIRED_APIS=(
    "iam.googleapis.com"
    "cloudbuild.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "serviceusage.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    if ! gcloud services list --enabled --filter="name:$api" --format="value(name)" --project="$PROJECT_ID" | grep -q "$api"; then
        echo "ERROR: Required API $api is not enabled"
        echo "Enable it with: gcloud services enable $api --project=$PROJECT_ID"
        exit 1
    fi
done
echo "All required APIs are enabled ✓"

# Create service account for SDK Terraform automation
SA_EMAIL="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"

if gcloud iam service-accounts describe "$SA_EMAIL" >/dev/null 2>&1; then
    echo "Service account terraform-automation already exists, skipping creation"
else
    echo "Creating terraform-automation service account..."
    gcloud iam service-accounts create terraform-automation \
      --display-name="SDK Terraform Automation Service Account" \
      --description="Service account for automated SDK repository Terraform deployments" \
      --project="$PROJECT_ID"
    echo "Service account created ✓"
fi

# Grant necessary permissions
echo "Granting permissions to terraform-automation..."

# Cloud Build permissions
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.builder"

# Secret Manager permissions (to read GitHub token and manage IAM policies for secrets)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.admin"

# Storage permissions (for Terraform state)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# IAM permissions (to manage service accounts created by the module)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.projectIamAdmin"

# Cloud Scheduler permissions (to manage scheduled jobs)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudscheduler.admin"

# Pub/Sub permissions (to manage topics for triggers)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/pubsub.admin"

# Service Account User permissions (to act as service accounts)
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountUser"

echo "Service account setup completed!"

# Grant Secret Manager Admin role to Cloud Build service account for GitHub connection
echo "Granting Secret Manager permissions to Cloud Build service account..."
# Get the Cloud Build service account (format: service-<PROJECT_NUMBER>@gcp-sa-cloudbuild.iam.gserviceaccount.com)
PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
CLOUD_BUILD_SA="service-${PROJECT_NUMBER}@gcp-sa-cloudbuild.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${CLOUD_BUILD_SA}" \
  --role="roles/secretmanager.admin"

echo "Cloud Build service account permissions granted ✓"
echo "Setup completed successfully!"