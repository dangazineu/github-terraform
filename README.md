# GitHub SDK Repository Management with Cloud Build

This repository provides a comprehensive Terraform solution for managing SDK GitHub repositories with integrated Google Cloud Build configurations. Designed specifically for SDK organizations, it includes a reusable module, production-ready implementations, and self-managing CI/CD infrastructure that automatically applies changes when code is pushed to the main branch.

## Quick Start

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Set Required Variables**
   ```bash
   export TF_VAR_github_token="your-github-token"
   export TF_VAR_gcp_project_id="your-sdk-project"
   export TF_VAR_github_owner="your-sdk-org"
   ```

3. **Apply Configuration**
   ```bash
   terraform plan
   terraform apply
   ```

## Repository Structure

```
terraform-github-sdk-module/
├── README.md                           # This documentation
├── .gitignore                          # Git ignore patterns
│
├── modules/                            # Reusable Terraform modules
│   └── github-repo-with-cloudbuild/    # Main module
│       ├── variables.tf                # Module input variables
│       ├── locals.tf                   # Local computations
│       ├── main.tf                     # Core module resources
│       ├── outputs.tf                  # Module outputs
│       └── templates/                  # File templates
│           ├── cloudbuild.yaml.tpl     # Cloud Build configuration template
│           ├── update.sh               # Demo automation script
│           └── CODEOWNERS.tpl          # CODEOWNERS file template
│
├── main.tf                             # Main implementation example
│
├── backend.tf                          # Terraform backend configuration
├── terraform.tfvars                    # Variable values (gitignored)
├── terraform.tfvars.example            # Example variable configuration
│
├── cloudbuild.yaml                     # Self-managing Cloud Build pipeline
├── cloudbuild-pr.yaml                  # Pull request validation pipeline
│
└── setup/                              # Bootstrap setup scripts (run once)
    ├── service-accounts.sh             # Creates terraform-automation service account
    ├── secrets.sh                      # Creates github-token secret for Terraform
    └── triggers.sh                     # Creates triggers for this infrastructure repo
```

## Documentation

For detailed information about the module architecture, use cases, and implementation details, see [SPEC.md](./SPEC.md).