#!/bin/bash

# PR Validation Script
# This script runs the same validations as the CI/CD pipeline
# Run this before submitting a PR to catch issues early

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===========================================${NC}"
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if terraform is installed
check_terraform() {
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform to run validation."
        exit 1
    fi
}

# Check terraform formatting
check_formatting() {
    print_header "Step 1: Terraform Formatting Check"
    
    if terraform fmt -check=true -diff=true; then
        print_step "Terraform formatting is correct"
    else
        print_error "Terraform files are not properly formatted"
        echo "Run 'terraform fmt' to fix formatting issues"
        return 1
    fi
}

# Validate terraform configuration
validate_terraform() {
    print_header "Step 2: Terraform Configuration Validation"
    
    echo "Initializing Terraform..."
    terraform init -backend=false
    
    if terraform validate; then
        print_step "Terraform configuration is valid"
    else
        print_error "Terraform configuration is invalid"
        return 1
    fi
}

# Check for security issues
check_security() {
    print_header "Step 3: Security Checks"
    
    # Check for exposed secrets (excluding example patterns)
    echo "Checking for exposed secrets..."
    if grep -r "ghp_[A-Za-z0-9]\{36\}" . --exclude-dir=.git --exclude="*.md" --exclude="*.sh" --exclude="*.yml" --exclude="*.yaml" || \
       grep -r "sk-[A-Za-z0-9]\{48\}" . --exclude-dir=.git --exclude="*.md" --exclude="*.sh" --exclude="*.yml" --exclude="*.yaml" || \
       grep -r "AKIA[A-Z0-9]\{16\}" . --exclude-dir=.git --exclude="*.md" --exclude="*.sh" --exclude="*.yml" --exclude="*.yaml"; then
        print_error "Actual secrets found in code"
        echo "Remove secrets from code and use Secret Manager instead"
        return 1
    fi
    
    # Check for hardcoded credentials
    echo "Checking for hardcoded credentials..."
    if grep -ri "password\s*=" . --include="*.tf" --include="*.tfvars" || \
       grep -ri "secret\s*=" . --include="*.tf" --include="*.tfvars" | grep -v "secret_id\|secret_manager"; then
        print_warning "Potential hardcoded credentials found"
        echo "Review credential usage and ensure secrets are properly managed"
    fi
    
    print_step "Security checks completed"
}

# Check syntax issues
check_syntax() {
    print_header "Step 4: Additional Syntax Checks"
    
    # Check for balanced braces
    echo "Checking brace balance..."
    for file in *.tf; do
        if [ -f "$file" ]; then
            open_braces=$(grep -o '{' "$file" | wc -l)
            close_braces=$(grep -o '}' "$file" | wc -l)
            if [ "$open_braces" -ne "$close_braces" ]; then
                print_error "Unbalanced braces in $file: $open_braces opening, $close_braces closing"
                return 1
            fi
        fi
    done
    
    print_step "Syntax checks passed"
}

# Optional: Run terraform plan if variables are provided
check_plan() {
    print_header "Step 5: Terraform Plan (Optional)"
    
    # Check if required variables are set
    if [ -z "${TF_VAR_github_token:-}" ] || \
       [ -z "${TF_VAR_gcp_project_id:-}" ] || \
       [ -z "${TF_VAR_github_owner:-}" ]; then
        print_warning "Terraform variables not set, skipping plan validation"
        echo "To run plan validation, set these environment variables:"
        echo "  export TF_VAR_github_token=\"your-token\""
        echo "  export TF_VAR_gcp_project_id=\"your-project\""
        echo "  export TF_VAR_github_owner=\"your-org\""
        echo "  export TF_VAR_github_app_id=\"your-app-id\""
        echo "  export TF_VAR_sdk_automation_github_app_id=\"your-automation-app-id\""
        return 0
    fi
    
    echo "Running terraform plan..."
    terraform init
    
    if terraform plan -detailed-exitcode -out=validation.tfplan; then
        print_step "Terraform plan succeeded with no changes"
    else
        PLAN_EXIT_CODE=$?
        if [ $PLAN_EXIT_CODE -eq 1 ]; then
            print_error "Terraform plan failed with errors"
            return 1
        elif [ $PLAN_EXIT_CODE -eq 2 ]; then
            print_warning "Terraform plan succeeded with changes detected"
            echo "This is expected for most PRs that modify infrastructure"
        fi
    fi
    
    # Cleanup
    rm -f validation.tfplan
}

# Main execution
main() {
    print_header "PR Validation Script"
    echo "This script validates your changes before submitting a PR"
    echo ""
    
    check_terraform
    
    # Run all validation steps
    if check_formatting && \
       validate_terraform && \
       check_security && \
       check_syntax && \
       check_plan; then
        echo ""
        print_header "🎉 All Validations Passed!"
        echo -e "${GREEN}Your changes are ready for PR submission${NC}"
        echo ""
        echo "Next steps:"
        echo "1. Commit your changes: git add . && git commit -m 'Your message'"
        echo "2. Push to your branch: git push origin your-branch-name"
        echo "3. Create a pull request on GitHub"
    else
        echo ""
        print_header "❌ Validation Failed"
        echo -e "${RED}Please fix the issues above before submitting a PR${NC}"
        exit 1
    fi
}

# Run main function
main "$@"