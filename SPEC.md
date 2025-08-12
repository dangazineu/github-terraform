# GitHub SDK Repository Management with Cloud Build

This repository provides a comprehensive Terraform solution for managing SDK GitHub repositories with integrated Google Cloud Build configurations. Designed specifically for SDK organizations, it includes a reusable module, production-ready implementations, and self-managing CI/CD infrastructure that automatically applies changes when code is pushed to the main branch.

## What This Repository Contains

### 🏗️ **Core Module** (`modules/github-repo-with-cloudbuild/`)
A reusable Terraform module that creates SDK GitHub repositories with:
- **Cloud Build Integration**: Scheduled builds that fetch GitHub tokens from Google Cloud Secret Manager (demo: every 5 minutes, production: weekly)
- **CODEOWNERS Protection**: Automatic protection of CI/CD files requiring SDK team approval for changes
- **Branch Protection**: Enforced pull request reviews and code owner approval requirements
- **Custom Scripts**: Template-based token processing scripts for each SDK repository
- **Flexible Configuration**: Customizable scheduling, service accounts, and language-specific team ownership rules

### 📝 **Implementation Example**
- **Main Implementation** (`main.tf`): Production-ready example creating multiple SDK repositories (Python, Go, Database, GenAI) with comprehensive feature demonstration

### 🔄 **Self-Managing Infrastructure**
- **Automated CI/CD** (`cloudbuild.yaml`): Automatically validates, plans, and applies Terraform changes on pushes to main
- **PR Validation** (`cloudbuild-pr.yaml`): Plan-only validation for pull requests
- **Remote State Management** (`backend.tf`): Google Cloud Storage backend for team collaboration

## How It Operates

### 🚀 **SDK Repository Lifecycle Management**
1. **Creation**: Module creates SDK GitHub repositories with all necessary files and configurations
2. **Protection**: CODEOWNERS and branch protection prevent unauthorized changes to critical SDK files
3. **Automation**: Each SDK repository gets Cloud Build configurations for automated operations (demo: timestamp PRs every 5 minutes, production: configurable weekly schedules)
4. **Maintenance**: Self-managing pipeline keeps all SDK repositories up-to-date when changes are made

### 🔐 **Security & Access Control**
- **Service Account Isolation**: Each SDK repository uses its own dedicated service account
- **Secret Segregation**: Each SDK accesses only its own API tokens and credentials from Secret Manager
- **Team-Based Approval**: CODEOWNERS ensures appropriate SDK teams review changes to CI/CD configurations
- **Secure Token Storage**: SDK API tokens and publishing credentials stored in Secret Manager, never in code

### ⚙️ **SDK Automation Workflow**
For each managed SDK repository:
1. **Trigger**: Cloud Scheduler triggers builds (demo: every 5 minutes, production: weekly)
2. **Authentication**: Cloud Build assumes SDK-specific service account (auto-created by Terraform)
3. **Private Key Retrieval**: Fetches shared GitHub App private key from Secret Manager
4. **Installation ID Retrieval**: Fetches repository-specific installation ID from Secret Manager
5. **JWT Generation**: Creates signed JWT using private key and GitHub App ID
6. **Token Exchange**: Exchanges JWT for repository-scoped installation token (1-hour expiry)
7. **Demo Logic**: Closes any existing PRs, then creates automated PRs with timestamp updates
8. **Cleanup**: Securely removes all tokens and keys from build environment

### 🔄 **SDK Development Workflow**
1. **Feature Development**: Create feature branch, make changes to SDK module or configurations
2. **PR Creation**: Open pull request → triggers validation pipeline (plan only)
3. **Review Process**: SDK teams review both code changes and Terraform plan output
4. **Merge to Main**: Approved changes merged → triggers full pipeline (validate → plan → apply)
5. **Automatic Deployment**: New SDK repositories or configuration changes applied automatically

### 📊 **Monitoring & Observability**
- **Cloud Build Logs**: Detailed logging for all Terraform operations
- **Artifact Storage**: Terraform plans and outputs stored in Google Cloud Storage
- **Output Commands**: Automatic generation of setup commands for manual GCP resource creation

## Use Cases

### 🏢 **SDK Organization Management**
- Standardize CI/CD configurations across multiple SDK repositories
- Enforce security policies through CODEOWNERS and branch protection for SDK teams
- Demonstrate automated CI/CD capabilities through timestamp update PRs as proof-of-concept

### 🔧 **SDK DevOps Automation**
- Template-driven SDK repository creation with language-specific configurations
- Automated compliance with security and operational standards for SDK development
- Centralized management of Cloud Build pipelines for all SDK repositories

### 📈 **Scalable SDK Infrastructure**
- Add new SDK repositories by simply updating configuration files
- Consistent patterns for service account management and API token access
- Self-documenting infrastructure with generated setup commands for each SDK

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
│           ├── update.sh               # Demo automation script (timestamp PR creation)
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
    ├── secrets.sh                      # Creates github-token and github-app-id secrets
    └── triggers.sh                     # Creates triggers for this infrastructure repo
```

## Setup Instructions

This setup follows a clear progression:

## 🏗️ **Production Workflow** (Automated)
1. **Bootstrap Setup** (one-time): Create infrastructure management foundation  
2. **GitHub App Integration** (one-time): Create dedicated app for SDK automation
3. **Automatic Deployment**: Push code changes → Cloud Build automatically deploys SDK repositories

## 🔧 **Manual Testing Workflow** (Optional)
1. **Bootstrap Setup** (one-time): Same as production
2. **GitHub App Integration** (one-time): Same as production
3. **Manual SDK Deployment**: Test locally before relying on automation  

**🚀 Quick Start**: Complete sections 1, 2, then push changes to trigger automatic deployment.

### Prerequisites (Brand New Setup)

For a completely fresh GitHub organization and GCP project, complete these prerequisites first:

#### A. Tool Setup
```bash
# 1. Install required tools (if not already installed)
# gcloud CLI: https://cloud.google.com/sdk/docs/install
# terraform: https://developer.hashicorp.com/terraform/install
# git: https://git-scm.com/downloads

# 2. Authenticate with Google Cloud
gcloud auth login
gcloud auth application-default login

# 3. Verify setup
gcloud projects describe $PROJECT_ID
gcloud services list --enabled --project=$PROJECT_ID
```

#### B. Google Cloud Project Setup
```bash
# 1. Create new GCP project (or use existing)
gcloud projects create $PROJECT_ID --name="SDK Automation Project"

# 2. Set as default project
gcloud config set project $PROJECT_ID

# 3. Enable billing (required - do this in Cloud Console or via CLI if you have billing admin)
# Go to: https://console.cloud.google.com/billing/linkedaccount?project=$PROJECT_ID
# Alternatively, use the following commands:
gcloud billing accounts list

# Look for an ID like 0X0X0X-0X0X0X-0X0X0X.
export BILLING_ACCOUNT_ID="0X0X0X-0X0X0X-0X0X0X"
gcloud billing projects link $PROJECT_ID --billing-account=$BILLING_ACCOUNT_ID

# Verify that the project has billing enabled
gcloud billing projects describe $PROJECT_ID

# 4. Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
gcloud services enable cloudscheduler.googleapis.com
gcloud services enable pubsub.googleapis.com
gcloud services enable iam.googleapis.com

# 5. Verify your user has necessary permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="user:$(gcloud config get-value account)" \
  --role="roles/owner"
```

#### C. GitHub Organization Setup

```bash
# Use only if fine-grained PATs are not supported in your organization
# or if you encounter compatibility issues with Terraform provider
#
# Go to: https://github.com/settings/tokens/new
# Scopes needed: repo, admin:org, admin:repo_hook
# Save this token as $GITHUB_TOKEN
#
# Note: Classic PATs have broader access and don't expire by default.
# Consider setting an expiration date for security.
```

##### Important Notes on Token Types
Fine-Grained PAT Advantages:
 - Repository-scoped access (more secure)
 - Granular permissions following least-privilege principle
 - Mandatory expiration (max 1 year)
 - Better audit trail

Known Limitations (as of 2024):
 - Some Terraform GitHub provider resources may not fully support fine-grained PATs
 - If you encounter "403 Resource not accessible by personal access token" errors
   during terraform apply, you may need to use a classic PAT
 - GitHub App installation management specifically has known issues with fine-grained PATs

### 1. Bootstrap Setup (Run Once)

#### 1.1. Set Environment Variables
```bash
export PROJECT_ID="your-project-id"
export GITHUB_OWNER="your-github-org"
export GITHUB_TOKEN="your-github-token"
export REPO_NAME="terraform-github-sdk-module"  # Must match the repo name from step 0
```

#### 1.2. Create Infrastructure Management Service Account
```bash
./setup/service-accounts.sh $PROJECT_ID
```
This script will:
- Create the terraform-automation service account
- Grant necessary IAM permissions for Terraform operations
- Grant Secret Manager Admin permissions to the Cloud Build service account (required for GitHub connection)

#### 1.3. Connect Cloud Build to GitHub and Create Secrets

Cloud Build needs access to your GitHub repositories through the **1st generation GitHub App** integration. This is a **one-time setup per GitHub organization**. During this process, you'll get the GitHub App ID needed for the secrets.

**Step 3a: Connect GitHub via Cloud Console**

1. Go to: https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID
2. Select **"GitHub (Cloud Build GitHub App)"** - NOT "GitHub (Cloud Build GitHub App 2nd gen)"
3. Authenticate with GitHub and authorize the Cloud Build app
4. Choose your GitHub organization (`$GITHUB_OWNER`)
5. **Important:** Select repository access:
   - **Recommended:** Choose **"All repositories"** for fully automated SDK management
   - Alternative: Select specific repositories (you'll need to manually add new ones later)
6. Complete the installation

**Verify Connection:**
After setup, verify your repository appears in the 1st gen repositories list:
- Go to: https://console.cloud.google.com/cloud-build/repositories/1st-gen?project=$PROJECT_ID
- You should see your repository listed there

**Step 3b: Get GitHub App ID and Create Secrets**

After connecting GitHub, get your App ID and create the required secrets:

```bash
# 1. Get your GitHub App ID from GitHub (easiest method for 1st gen connections):
# Go to GitHub → Settings → Integrations → GitHub Apps → Google Cloud Build → Configure
# The URL will be: https://github.com/settings/installations/INSTALLATION_ID
# The number at the end is your GitHub App installation ID (this is what Cloud Build needs)

# For your organization dg-ghtest, go to:
# https://github.com/organizations/dg-ghtest/settings/installations
# Click "Configure" on Google Cloud Build app, and check the URL

export GITHUB_APP_ID="123456"  # Replace with the installation ID from the URL

# Verify the App ID
echo "GitHub App ID (Installation ID): $GITHUB_APP_ID"

# 2. Create both secrets (GitHub token and App ID):
./setup/secrets.sh $PROJECT_ID $GITHUB_TOKEN $GITHUB_APP_ID
```

**Finding Your GitHub App Installation ID:**
- **GitHub UI (Recommended for 1st gen)**: Go to GitHub → Settings → Integrations → GitHub Apps → Google Cloud Build → Configure. The installation ID is in the URL.
- **Organization**: For org `dg-ghtest`, go to https://github.com/organizations/dg-ghtest/settings/installations
- **Personal**: Go to https://github.com/settings/installations  
- **Important**: Use the installation ID number from the URL, not the app name

**Note**: For 1st gen GitHub connections, the "App ID" that Cloud Build needs is actually the GitHub App **installation ID**, which you get from the GitHub settings URL.

**Repository Access Strategy:**

- **Option 1: All Repositories (Recommended for SDK Automation)**
  - Grant access to all current and future repositories
  - New SDK repositories created by Terraform will automatically have trigger access
  - No manual steps needed when adding new SDKs
  - Security is maintained through service account permissions

- **Option 2: Selected Repositories**
  - Choose specific repositories during setup
  - To add new repositories later:
    1. Go to GitHub: https://github.com/organizations/$GITHUB_OWNER/settings/installations
    2. Find "Google Cloud Build" app
    3. Click "Configure" and add repositories
  - More restrictive but requires manual steps for new SDKs

**What This Enables:**
- Terraform can create triggers for any repository the GitHub App has access to
- The main infrastructure Terraform can automatically set up triggers for new SDK repositories
- Triggers are created as global resources (not regional) for 1st gen connections

**Important Notes:**
- This GitHub App connection is shared across all Cloud Build triggers in your project
- You only need to set it up once per GitHub organization
- 1st gen connections create **global** triggers (no region specification needed)
- The connection will work for both the infrastructure repository and all SDK repositories managed by Terraform

#### 1.4. Create Infrastructure Management Triggers

After connecting the GitHub App, use Terraform to create the Cloud Build triggers:

```bash
# Create triggers using Terraform (recommended)
./setup/create-triggers.sh $PROJECT_ID $GITHUB_OWNER $REPO_NAME
```

This script will:
- Initialize Terraform in the setup directory
- Create two **global** Cloud Build triggers (1st gen triggers are not regional):
  - `infra-main-apply`: Auto-applies Terraform changes on push to main
  - `infra-pr-plan`: Runs Terraform plan on pull requests
- Use the service account created in step 2 (with full resource name format)

**Troubleshooting:**
- If you get "Repository mapping does not exist" error, ensure you selected the 1st gen GitHub App, not 2nd gen
- If you get "Invalid argument" errors, verify the service account exists and the GitHub repository is visible in the 1st gen list
- The Terraform configuration in `setup/triggers.tf` does NOT use `location` parameter for 1st gen triggers

### 2. GitHub App Integration (One-Time Setup)

**⚠️ Important**: This is a **one-time setup** that enables GitHub App authentication for all SDK repositories. You need to complete this **before** deploying SDK repositories so they are created with working automation.

**Why a Dedicated GitHub App is Required:**
- SDK automation scripts need **Pull requests: Write** permission to create/close PRs
- Cloud Build GitHub App only has **Pull requests: Read** permission (for triggers)  
- The SDK automation performs different operations than Cloud Build's repository access

#### 2.1. Create Dedicated GitHub App

```bash
# 1. Create new GitHub App specifically for SDK automation
# Go to GitHub → Settings → Developer settings → GitHub Apps → New GitHub App

# App Settings:
# - Name: "SDK Automation for ${GITHUB_OWNER}"  
# - Homepage URL: "https://github.com/${GITHUB_OWNER}"
# - Webhook URL: "https://example.com/webhook" (unused but required)

# Required Permissions:
# - Repository permissions → Contents: Write (clone, create files, push branches)
# - Repository permissions → Pull requests: Write (create/close PRs)  
# - Repository permissions → Metadata: Read (get repo info, default branch)

# 2. After creation, you'll see: "Registration successful. You must generate a private key in order to install your GitHub App."

# 3. Generate Private Key:
# - Click "Generate a private key" button
# - Download the .pem file (e.g., sdk-automation-for-dg-ghtest.2025-08-12.private-key.pem)
# - Save the App ID displayed on the page (e.g., 1770057)

export NEW_APP_ID="1770057"  # Replace with your actual App ID
```

#### 2.2. Install App on Organization

```bash
# 1. Install the GitHub App on your organization  
# - On the GitHub App page, click "Install App" in left sidebar
# - Select your organization (e.g., dg-ghtest)
# - Choose "All repositories" (recommended for full automation)
# - Click "Install"

# 2. Installation is complete - no need to manually note installation ID
# The automation scripts will automatically discover installation IDs for each repository
```

#### 2.3. Add Private Key to Secret Manager

```bash
# Add the GitHub App private key (shared across all SDK repos)
# Replace the path with where you downloaded the private key file
cat sdk-automation-for-dg-ghtest.2025-08-12.private-key.pem | gcloud secrets versions add github-app-private-key --data-file=- --project=$PROJECT_ID

# Note: Do NOT commit the private key file to git
echo "*.private-key.pem" >> .gitignore
```

#### 2.4. Verify GitHub App Setup

```bash
# Test that the private key was added successfully
gcloud secrets versions access latest --secret="github-app-private-key" --project="$PROJECT_ID" | head -1

# Should return: -----BEGIN PRIVATE KEY-----

# Note: Installation ID secrets will be automatically populated by the SDK automation scripts
# when they first run for each repository

# Update your environment variable to use the new GitHub App ID
export TF_VAR_github_app_id="1770057"  # Replace with your actual App ID
```

### 3. SDK Repository Deployment (Manual Testing)

**⚠️ Important**: This section is for **manual testing only**. In production, these steps are **automatically executed** by the Cloud Build triggers created in the Bootstrap section when you push changes to the main branch.

**When to use this section**:
- Testing the setup locally before relying on automation
- Troubleshooting issues with the automated pipeline
- Understanding what the `cloudbuild.yaml` does behind the scenes

**For production use**: Simply push your changes to the main branch, and Cloud Build will automatically execute these steps.

#### 3.1. Set Required Variables
```bash
# Use the same variables from bootstrap setup
export TF_VAR_github_token="$GITHUB_TOKEN"
export TF_VAR_gcp_project_id="$PROJECT_ID"
export TF_VAR_github_owner="$GITHUB_OWNER"
export TF_VAR_github_app_id="$GITHUB_APP_ID"
```

#### 3.2. Deploy SDK Infrastructure
```bash
# Validate formatting
terraform fmt -check=true -diff=true

# Initialize with backend (created during bootstrap)
terraform init

# Plan the SDK repository deployment
terraform plan -out=main.tfplan

# Review what will be created
terraform show main.tfplan

# Deploy the SDK repositories
terraform apply main.tfplan
```

#### 3.3. Review Created Resources
```bash
# View setup commands for next steps
terraform output github_app_setup_commands

# Check what was created
gcloud secrets list --project=$PROJECT_ID
curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$GITHUB_OWNER/repos" | grep '"name"'
```

**What Gets Created**:
- 4 GitHub SDK repositories (python-sdk, go-sdk, databases-sdk, genai-sdk)
- Repository files (cloudbuild.yaml, scripts, CODEOWNERS)
- Service accounts for each repository
- Secret Manager containers (**now populated** with GitHub App secrets from step 2)
- Pub/Sub topics for Cloud Build triggers
- **Self-contained triggers**: Cloud Build triggers with inline configurations that clone public repositories directly (no GitHub App connection required for Cloud Build)
- **Working automation**: Repositories are created with functional PR automation

### 4. Verify Complete Setup

After completing all steps, verify your SDK automation is working:

#### 4.1. Check Infrastructure Status
```bash
# Verify all repositories exist
curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/orgs/$GITHUB_OWNER/repos" | grep '"name"' | grep sdk

# Check Cloud Build triggers (including infrastructure triggers from bootstrap)
gcloud builds triggers list --project=$PROJECT_ID

# Verify all secrets are populated
gcloud secrets list --project=$PROJECT_ID | grep -E "(github-app|installation-id)"
```

#### 4.2. Test SDK Repository Automation
```bash
# Trigger a manual build to test (optional)
gcloud builds triggers run python-sdk-weekly-trigger --project=$PROJECT_ID

# Check build history
gcloud builds list --project=$PROJECT_ID --limit=5

# Monitor scheduler jobs (demo: trigger every 5 minutes)
gcloud scheduler jobs list --project=$PROJECT_ID
```

## Final Architecture

You now have a complete SDK automation system with:

**🏗️ Infrastructure Management**:
- Self-updating infrastructure via Cloud Build triggers on this repo
- Terraform backend in GCS with state management
- Automated service account management

**📦 SDK Repositories** (4 repositories created):
- **python-sdk**: Automated builds every 5 minutes (demo) / 2:00 AM EST weekly (production)
- **go-sdk**: Automated builds every 5 minutes (demo) / 2:30 AM EST weekly (production)  
- **databases-sdk**: Automated builds every 5 minutes (demo) / 1:30 AM PST weekly (production)
- **genai-sdk**: Automated builds every 5 minutes (demo) / 3:00 AM EST weekly (production)

**🔐 Security Features**:
- GitHub App authentication with short-lived (1-hour) tokens
- Repository-scoped access (each SDK can only access itself)
- CODEOWNERS protection on all CI/CD files
- Dedicated service accounts per repository
- Branch protection rules (requires GitHub Pro for private repos)

**⚙️ Automation Components**:
- Cloud Build configurations in each repository
- Cloud Scheduler jobs for automated execution
- Pub/Sub topics for trigger communication
- Helper scripts for token management and health checks

---

## Cleanup

To remove all created resources:
```bash
# Remove SDK repositories and infrastructure
terraform destroy

# Remove bootstrap infrastructure (optional)
cd setup/
terraform destroy
```

**Note**: This will delete all SDK repositories, service accounts, secrets, and triggers. Use with caution.

## Authentication Architecture

This system uses GitHub App authentication for enhanced security and access control:

### 🏗️ GitHub App Structure

```
┌─────────────────┐
│   GitHub App    │ ← One app created once during bootstrap
│ "SDK Automation"│
└─────────────────┘
         │
         │ Installed on multiple repos
         ▼
┌──────────────────────────────────────────┐
│              Installations               │
├──────────────┬──────────────┬────────────┤
│   python-sdk │    go-sdk    │ genai-sdk  │ ← Each repo gets unique installation ID
│Installation  │Installation  │Installation│
│   ID: 123    │   ID: 456    │  ID: 789   │
└──────────────┴──────────────┴────────────┘
```

### 🔐 Token Generation Per Repository

Each Cloud Build job generates a **repository-specific token**:

```bash
# In python-sdk Cloud Build:
INSTALLATION_TOKEN=$(generate_token_for_installation_id 123)  # Only works for python-sdk

# In go-sdk Cloud Build:
INSTALLATION_TOKEN=$(generate_token_for_installation_id 456)  # Only works for go-sdk
```

### 🗝️ Secret Management Strategy

**Shared Secrets:**
- `github-app-private-key`: GitHub App's private key (PEM format) - shared across all repositories

**Repository-Specific Secrets:**
- `python-sdk-installation-id`: Installation ID for python-sdk repository
- `go-sdk-installation-id`: Installation ID for go-sdk repository
- `databases-sdk-installation-id`: Installation ID for databases-sdk repository
- `genai-sdk-installation-id`: Installation ID for genai-sdk repository

### 🏢 Service Account Architecture

**1. Infrastructure Management Service Account (Bootstrap)**
- **Purpose**: Runs Terraform to manage SDK repositories
- **Name**: `terraform-automation@{project}.iam.gserviceaccount.com`
- **Setup**: Created once using `./setup/service-accounts.sh`
- **Permissions**: Can create other service accounts, triggers, secrets

**2. Repository-Specific Service Accounts (Automated)**
- **Purpose**: Run Cloud Build jobs for individual SDK repositories
- **Names**: `{repo-name}-sa@{project}.iam.gserviceaccount.com` (e.g., `python-sdk-sa`)
- **Setup**: Created automatically by Terraform for each repository
- **Permissions**: Access to shared private key + their specific installation ID

### 🔒 Security Benefits

**Automatic Access Segregation:**
- **python-sdk Cloud Build** → Can only access `python-sdk` repository
- **go-sdk Cloud Build** → Can only access `go-sdk` repository
- **No cross-repository access possible** (enforced by GitHub API)

**Token Characteristics:**
- **Short-lived**: 1 hour expiration (vs permanent PATs)
- **Repository-scoped**: Can't access other repositories
- **Permission-limited**: Only contents:write + pull_requests:write
- **Automatic rotation**: New token generated for each build


## Questions and Answers

### Business Context and Use Cases

**Q: What is the primary business driver for the weekly scheduled jobs?**
A: The weekly scheduled jobs create automated timestamp update PRs to demonstrate the end-to-end funcionality of this infrastructure. Actual business logic will be implemented later.

**Q: Who is the intended user of this module?**
A: The module is designed for DevOps/Platform teams managing multiple repositories at scale. It provides standardized CI/CD configurations while allowing individual development teams to own their repository-specific logic through the customizable `update.sh` script.

**Q: How is success measured for this implementation?**
A: Success metrics include:
- Reduction in manual repository setup time (from hours to minutes)
- 100% compliance with security policies (CODEOWNERS, branch protection)
- Zero credential exposure incidents
- Successful demonstration of end-to-end automation capabilities
- Framework readiness for production business logic implementation

### Technical Implementation Details

**Q: How does the automated infrastructure creation work?**
A: The module creates all required infrastructure automatically through Terraform:
- **Cloud Build Triggers**: Automatically created for each SDK repository with inline build configurations
- **Self-Contained Approach**: Triggers clone public repositories directly without requiring GitHub App connections to Cloud Build
- **Cloud Scheduler Jobs**: Automatically configured for weekly execution
- **Pub/Sub Topics**: Automatically created for trigger communication
- **Full Integration**: All components are properly linked with dependencies
The only manual step remaining is creating secrets in Secret Manager for security reasons.

**Q: How do the Cloud Build triggers work without repository connections?**
A: The triggers use an innovative approach:
- **Inline Build Configuration**: Instead of referencing external `cloudbuild.yaml` files, triggers contain embedded build steps
- **Public Repository Cloning**: Build steps directly clone public GitHub repositories using standard git clone
- **GitHub App Authentication**: Scripts within the cloned repository handle GitHub App token generation for API operations
- **No Cloud Build GitHub Connection Required**: Eliminates the need to connect SDK repositories to Cloud Build's GitHub integration
- **Simplified Management**: New repositories work immediately without manual Cloud Build repository connections

**Q: How should the main.tf be customized for production use?**
A: The main.tf contains example repositories that should be replaced with your actual repositories. Update the repository configurations in the `locals.repositories` block with your real repository names, descriptions, service accounts, and team assignments.

**Q: What's the correct secret naming convention?**
A: Secrets should use underscores, not hyphens. The correct commands are:
```bash
gcloud secrets create python_sdk --project=your-project  # Correct
gcloud secrets create python-sdk --project=your-project  # Incorrect
```
The module automatically converts hyphens to underscores in the `locals.tf` to ensure consistency.

**Q: What specific tokens are managed by this system?**
A: The system uses GitHub App authentication with installation tokens for secure, repository-scoped access:
- **GitHub App Private Key**: Shared secret for generating JWTs
- **Installation IDs**: Repository-specific installation identifiers
- **Installation Tokens**: Short-lived (1-hour), repository-scoped access tokens
- **Automatic Segregation**: Each repository can only access itself via GitHub's API enforcement

### Operational Requirements

**Q: How are failures in weekly jobs handled?**
A: Implement monitoring and alerting:
1. Configure Cloud Build to publish to Pub/Sub on failure
2. Set up Cloud Functions to process failure events
3. Send alerts to Slack/PagerDuty/email
4. Consider implementing automatic retries with exponential backoff
5. Maintain runbooks for common failure scenarios

**Q: What's the process for onboarding a new repository?**
A: The standard workflow is:
1. Development team submits PR to `main.tf` adding their repository configuration
2. Platform team reviews the PR, checking service account permissions and schedule
3. After merge, the self-managing pipeline creates the repository
4. Team manually creates required secrets in Secret Manager
5. Team sets up Cloud Build triggers using the generated commands

**Q: How are repository deletions handled?**
A: Repository deletion should be a controlled process:
1. Remove the repository from `main.tf`
2. Create PR with clear description of deletion intent
3. Require approval from repository owners and platform team
4. After merge, Terraform will delete the GitHub repository
5. Manually clean up associated GCP resources (triggers, secrets)

### Security and Compliance

**Q: Can the terraform-automation service account permissions be reduced?**
A: Yes, consider these more granular permissions:
- Replace `storage.admin` with `storage.objectAdmin` on specific buckets
- Replace `resourcemanager.projectIamAdmin` with custom role containing only needed permissions
- Use Workload Identity Federation instead of service account keys where possible

**Q: How is the initial bootstrap handled?**
A: The bootstrap process involves:
1. Manually create the GCS bucket for Terraform state
2. Create the terraform-automation service account
3. Store the initial GitHub token in Secret Manager
4. Run Terraform locally with admin credentials for first apply
5. Set up Cloud Build triggers to enable self-management

**Q: What's the break-glass procedure if CODEOWNERS team is unavailable?**
A: Establish an emergency procedure:
1. Document admin override process in team runbook
2. Use repository admin privileges to temporarily bypass protection
3. Require post-incident review for any emergency changes
4. Consider adding a secondary approval team for redundancy

### Scaling and Maintenance

**Q: How do you handle API rate limits at scale?**
A: Implement rate limit management:
- Use GitHub Apps instead of PATs for better rate limits
- Implement exponential backoff in API calls
- Stagger weekly job schedules across repositories
- Monitor API usage and set up alerts before hitting limits
- Consider using GitHub's GraphQL API for more efficient queries

**Q: How are breaking changes to the module handled?**
A: Follow semantic versioning and staged rollouts:
1. Version the module using Git tags (v1.0.0, v1.1.0, etc.)
2. Test changes in non-production environments first
3. Use Terraform module sources with version constraints
4. Provide migration guides for breaking changes
5. Consider supporting multiple major versions simultaneously

**Q: How is configuration drift detected and corrected?**
A: Implement drift detection:
1. Run `terraform plan` on schedule to detect drift
2. Use GitHub's audit log API to track manual changes
3. Automatically create issues for detected drift
4. Consider using tools like Atlantis for drift remediation
5. Enforce "infrastructure as code only" policy through training and access controls

### Additional Recommendations

**1. Testing Strategy**
- Implement Terratest for automated module testing
- Create separate test project for CI/CD validation
- Test disaster recovery procedures quarterly

**2. Cost Optimization**
- Set up budget alerts for Cloud Build usage
- Monitor Secret Manager access patterns
- Consider using Cloud Build pools for better resource utilization

**3. Compliance and Governance**
- Integrate with Cloud Asset Inventory for compliance reporting
- Use Policy Controller for enforcing organizational policies
- Implement regular security audits of service accounts and secrets

**4. Migration Path**
- For organizations with existing repositories, create a migration tool
- Support gradual adoption with opt-in mechanism
- Provide clear documentation for converting existing repos