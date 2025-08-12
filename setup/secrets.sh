#!/bin/bash

# Setup script for creating SDK secrets in Secret Manager

set -euo pipefail

PROJECT_ID="${1}"
SDK_GITHUB_TOKEN="${2}"
GITHUB_APP_ID="${3:-}"

if [[ -z "${PROJECT_ID:-}" ]] || [[ -z "${SDK_GITHUB_TOKEN:-}" ]]; then
    echo "Usage: $0 <project_id> <github_token> [github_app_id]"
    echo "Example: $0 my-sdk-project ghp_xxxxxxxxxxxx 123456"
    echo ""
    echo "Arguments:"
    echo "  project_id     - Google Cloud Project ID"
    echo "  github_token   - GitHub Personal Access Token or Fine-grained PAT"
    echo "  github_app_id  - GitHub App ID (numeric, required for Cloud Build)"
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
if gcloud secrets describe sdk-github-token --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "GitHub token secret already exists, updating with new value..."
    echo "$SDK_GITHUB_TOKEN" | gcloud secrets versions add sdk-github-token \
      --data-file=- \
      --project="$PROJECT_ID"
else
    echo "Creating GitHub token secret..."
    echo "$SDK_GITHUB_TOKEN" | gcloud secrets create sdk-github-token \
      --data-file=- \
      --project="$PROJECT_ID"
fi
echo "GitHub token secret ready ✓"

# Grant access to the service account
echo "Granting access to terraform-automation service account..."
SA_EMAIL="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"

# Check if IAM binding already exists
if gcloud secrets get-iam-policy sdk-github-token --project="$PROJECT_ID" --format="value(bindings.members)" | grep -q "$SA_EMAIL"; then
    echo "Service account already has access to sdk-github-token secret"
else
    gcloud secrets add-iam-policy-binding sdk-github-token \
      --member="serviceAccount:$SA_EMAIL" \
      --role="roles/secretmanager.secretAccessor" \
      --project="$PROJECT_ID"
    echo "Access granted ✓"
fi

# Create secret for GitHub App ID (if provided)
if [[ -n "${GITHUB_APP_ID:-}" ]]; then
    if gcloud secrets describe github-app-id --project="$PROJECT_ID" >/dev/null 2>&1; then
        echo "GitHub App ID secret already exists, updating with new value..."
        echo "$GITHUB_APP_ID" | gcloud secrets versions add github-app-id \
          --data-file=- \
          --project="$PROJECT_ID"
    else
        echo "Creating GitHub App ID secret..."
        echo "$GITHUB_APP_ID" | gcloud secrets create github-app-id \
          --data-file=- \
          --project="$PROJECT_ID"
    fi
    echo "GitHub App ID secret ready ✓"

    # Grant access to the service account
    echo "Granting access to terraform-automation service account for github-app-id..."
    
    # Check if IAM binding already exists
    if gcloud secrets get-iam-policy github-app-id --project="$PROJECT_ID" --format="value(bindings.members)" | grep -q "$SA_EMAIL"; then
        echo "Service account already has access to github-app-id secret"
    else
        gcloud secrets add-iam-policy-binding github-app-id \
          --member="serviceAccount:$SA_EMAIL" \
          --role="roles/secretmanager.secretAccessor" \
          --project="$PROJECT_ID"
        echo "Access granted ✓"
    fi
else
    echo "⚠️  WARNING: GitHub App ID not provided. You'll need to create this secret manually:"
    echo "   gcloud secrets create github-app-id --data-file=<(echo 'YOUR_GITHUB_APP_ID') --project=$PROJECT_ID"
    echo "   gcloud secrets add-iam-policy-binding github-app-id --member='serviceAccount:$SA_EMAIL' --role='roles/secretmanager.secretAccessor' --project=$PROJECT_ID"
fi

echo "Secret setup completed!"