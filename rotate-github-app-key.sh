#!/bin/bash

# GitHub App Private Key Rotation Script
# This script helps rotate the private key for the SDK Automation GitHub App
# and update the secret in Google Secret Manager
#
# SCOPE: This script ONLY handles the GitHub App private key (github-app-private-key secret)
# NOTE: This script does NOT handle Personal Access Tokens (github-token secret)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GITHUB_APP_ID="1770057"  # SDK Automation GitHub App ID
SECRET_NAME="github-app-private-key"
PROJECT_ID="${PROJECT_ID:-$(gcloud config get-value project)}"

print_header() {
    echo -e "${BLUE}==========================================="
    echo -e "GitHub App Private Key Rotation"
    echo -e "App ID: $GITHUB_APP_ID"
    echo -e "Project: $PROJECT_ID"
    echo -e "===========================================${NC}"
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_manual_step() {
    echo -e "${YELLOW}[MANUAL ACTION REQUIRED]${NC} $1"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        print_error "No active gcloud authentication found. Please run: gcloud auth login"
        exit 1
    fi
    
    # Check if project is set
    if [[ -z "$PROJECT_ID" ]]; then
        print_error "PROJECT_ID not set. Please set it or configure gcloud: gcloud config set project YOUR_PROJECT_ID"
        exit 1
    fi
    
    # Check if secret exists
    if ! gcloud secrets describe "$SECRET_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
        print_error "Secret $SECRET_NAME does not exist in project $PROJECT_ID"
        exit 1
    fi
    
    print_step "Prerequisites check passed ✓"
}

show_manual_steps() {
    print_manual_step "You need to perform these manual steps in the GitHub App settings:"
    echo
    echo "1. Go to: https://github.com/settings/apps/sdk-automation-for-dg-ghtest"
    echo "2. Scroll down to 'Private keys' section"
    echo "3. Click 'Generate a private key'"
    echo "4. Download the .pem file (it will be named something like:"
    echo "   sdk-automation-for-dg-ghtest.YYYY-MM-DD.private-key.pem)"
    echo "5. Note the download location for the next step"
    echo
    print_warning "SECURITY: The old key will be automatically revoked when you generate a new one"
    echo
}

wait_for_key_file() {
    print_step "Waiting for new private key file..."
    echo "Please provide the path to the newly downloaded private key file:"
    read -p "Private key file path: " KEY_FILE_PATH
    
    # Expand tilde to home directory
    KEY_FILE_PATH="${KEY_FILE_PATH/#\~/$HOME}"
    
    if [[ ! -f "$KEY_FILE_PATH" ]]; then
        print_error "File not found: $KEY_FILE_PATH"
        exit 1
    fi
    
    # Verify it's a valid PEM file
    if ! grep -q "BEGIN RSA PRIVATE KEY\|BEGIN PRIVATE KEY" "$KEY_FILE_PATH"; then
        print_error "File does not appear to be a valid private key"
        exit 1
    fi
    
    print_step "Private key file validated ✓"
}

backup_current_key() {
    print_step "Creating backup of current key..."
    
    BACKUP_FILE="/tmp/github-app-key-backup-$(date +%Y%m%d-%H%M%S).pem"
    gcloud secrets versions access latest --secret="$SECRET_NAME" --project="$PROJECT_ID" > "$BACKUP_FILE"
    
    print_step "Current key backed up to: $BACKUP_FILE"
    print_warning "Keep this backup secure until you verify the new key works"
}

update_secret() {
    print_step "Updating secret in Google Secret Manager..."
    
    # Add new version to the secret
    gcloud secrets versions add "$SECRET_NAME" --data-file="$KEY_FILE_PATH" --project="$PROJECT_ID"
    
    print_step "Secret updated successfully ✓"
}

test_new_key() {
    print_step "Testing new key with GitHub API..."
    
    # Use the installation helper to test the key
    if [[ -f "./modules/github-repo-with-cloudbuild/templates/installation-helper.sh" ]]; then
        echo "Testing key with installation helper..."
        if ./modules/github-repo-with-cloudbuild/templates/installation-helper.sh test-key "$GITHUB_APP_ID" "$KEY_FILE_PATH"; then
            print_step "Key test passed ✓"
        else
            print_error "Key test failed. Please check the key and try again."
            print_warning "You can restore the backup if needed: gcloud secrets versions add $SECRET_NAME --data-file=$BACKUP_FILE --project=$PROJECT_ID"
            exit 1
        fi
    else
        print_warning "Installation helper not found. Please manually verify the key works."
    fi
}

cleanup_key_file() {
    print_step "Cleaning up..."
    
    if [[ -f "$KEY_FILE_PATH" ]]; then
        print_warning "Remember to securely delete the downloaded key file:"
        echo "  rm \"$KEY_FILE_PATH\""
        echo
        read -p "Delete the key file now? (y/N): " -r
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$KEY_FILE_PATH"
            print_step "Key file deleted ✓"
        fi
    fi
}

trigger_rebuild() {
    print_step "Triggering infrastructure rebuild to use new key..."
    
    # Check if Cloud Build trigger exists
    if gcloud builds triggers describe infra-main-apply --project="$PROJECT_ID" >/dev/null 2>&1; then
        echo "Triggering rebuild..."
        gcloud builds triggers run infra-main-apply --branch=main --project="$PROJECT_ID"
        print_step "Rebuild triggered ✓"
        echo "Monitor the build at: https://console.cloud.google.com/cloud-build/builds?project=$PROJECT_ID"
    else
        print_warning "Could not find infra-main-apply trigger. You may need to manually test the automation."
    fi
}

main() {
    print_header
    
    print_warning "This script will rotate the GitHub App private key for SDK Automation"
    print_warning "IMPORTANT: This script does NOT affect Personal Access Tokens (PATs)"
    print_warning "Make sure you have access to the GitHub App settings before proceeding"
    echo
    read -p "Continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
    
    check_prerequisites
    backup_current_key
    show_manual_steps
    wait_for_key_file
    update_secret
    test_new_key
    cleanup_key_file
    trigger_rebuild
    
    print_header
    print_step "Key rotation completed successfully! ✅"
    echo
    print_warning "Next steps:"
    echo "1. Monitor the Cloud Build to ensure it completes successfully"
    echo "2. Test the SDK automation by waiting for the next scheduled run"
    echo "3. If everything works, you can delete the backup: rm $BACKUP_FILE"
    echo
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0"
        echo "Rotates the GitHub App private key for SDK Automation"
        echo
        echo "This script will:"
        echo "1. Guide you through generating a new key in GitHub"
        echo "2. Update the secret in Google Secret Manager"
        echo "3. Test the new key"
        echo "4. Trigger a rebuild to use the new key"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac