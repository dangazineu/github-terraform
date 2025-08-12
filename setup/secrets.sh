#!/bin/bash

# Setup script for creating SDK secrets in Secret Manager

set -euo pipefail

PROJECT_ID="${1}"
GITHUB_TOKEN="${2}"

if [[ -z "${PROJECT_ID:-}" ]] || [[ -z "${GITHUB_TOKEN:-}" ]]; then
    echo "Usage: $0 <project_id> <github_token>"
    echo "Example: $0 my-sdk-project ghp_xxxxxxxxxxxx"
    exit 1
fi

echo "Setting up SDK secrets for project: $PROJECT_ID"

# Verify project exists and Secret Manager API is enabled
if ! gcloud projects describe "$PROJECT_ID" >/dev/null 2>&1; then
    echo "ERROR: Project '$PROJECT_ID' not found or not accessible"
    exit 1
fi

if ! gcloud services list --enabled --filter="name:secretmanager.googleapis.com" --format="value(name)" --project="$PROJECT_ID" | grep -q "secretmanager.googleapis.com"; then
    echo "ERROR: Secret Manager API is not enabled"
    echo "Enable it with: gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID"
    exit 1
fi

# Create secret for GitHub token
if gcloud secrets describe github-token --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "GitHub token secret already exists, updating with new value..."
    echo "$GITHUB_TOKEN" | gcloud secrets versions add github-token \
      --data-file=- \
      --project="$PROJECT_ID"
else
    echo "Creating GitHub token secret..."
    echo "$GITHUB_TOKEN" | gcloud secrets create github-token \
      --data-file=- \
      --project="$PROJECT_ID"
fi
echo "GitHub token secret ready ✓"

# Grant access to the service account
echo "Granting access to terraform-automation service account..."
SA_EMAIL="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if IAM binding already exists
if gcloud secrets get-iam-policy github-token --project="$PROJECT_ID" --format="value(bindings.members)" | grep -q "$SA_EMAIL"; then
    echo "Service account already has access to github-token secret"
else
    gcloud secrets add-iam-policy-binding github-token \
      --member="serviceAccount:$SA_EMAIL" \
      --role="roles/secretmanager.secretAccessor" \
      --project="$PROJECT_ID"
    echo "Access granted ✓"
fi

echo "Secret setup completed!"