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
    ├── secrets.sh                      # Creates github-token secret for Terraform
    └── triggers.sh                     # Creates triggers for this infrastructure repo
```

## Setup Instructions

This setup has two levels:
1. **Bootstrap Setup** (one-time): Use `setup/` scripts to create the infrastructure management service account and triggers
2. **SDK Repository Automation** (ongoing): Terraform automatically creates SDK repository resources

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

### Bootstrap Setup (Run Once)

#### 1. Set Environment Variables
```bash
export PROJECT_ID="your-project-id"
export GITHUB_OWNER="your-github-org"
export GITHUB_TOKEN="your-github-token"
export REPO_NAME="terraform-github-sdk-module"  # Must match the repo name from step 0
```

#### 2. Create Infrastructure Management Service Account
```bash
./setup/service-accounts.sh $PROJECT_ID
```
This script will:
- Create the terraform-automation service account
- Grant necessary IAM permissions for Terraform operations
- Grant Secret Manager Admin permissions to the Cloud Build service account (required for GitHub connection)

#### 3. Create GitHub Token Secret
```bash
./setup/secrets.sh $PROJECT_ID $GITHUB_TOKEN
```

#### 4. Connect Cloud Build to GitHub (Required - One-Time Setup)

Cloud Build needs access to your GitHub repositories through the **1st generation GitHub App** integration. This is a **one-time setup per GitHub organization**.

**Connect GitHub via Cloud Console:**

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

#### 5. Create Infrastructure Management Triggers

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

### SDK Repository Management (Automated)

#### 1. Initialize Terraform
```bash
terraform init
```

### 2. Set Required Variables (using bootstrap variables)
```bash
export TF_VAR_github_token="$GITHUB_TOKEN"
export TF_VAR_gcp_project_id="$PROJECT_ID"
export TF_VAR_github_owner="$GITHUB_OWNER"
```

### 3. Apply Configuration
```bash
terraform plan
terraform apply
```

### 4. GitHub App Setup and Secret Population

The Terraform will create empty secret containers. You need to create a GitHub App and populate the secrets:

**Note**: Cloud Build triggers, Cloud Scheduler jobs, Pub/Sub topics, service accounts, and secret containers are all created automatically by Terraform. Only GitHub App creation and secret population remain manual for security reasons.

## Running the Demo

### Prerequisites

1. **GitHub Personal Access Token**: Create a token with `repo` and `admin:org` permissions
2. **Google Cloud Project**: Have a GCP project with Cloud Build and Secret Manager APIs enabled
3. **Terraform**: Install Terraform >= 1.0

### Step 1: Set Up Variables (reuse bootstrap variables)

Create a `terraform.tfvars` file:
```hcl
github_token    = "your-github-token-here"
github_owner    = "your-sdk-org"
gcp_project_id  = "your-sdk-project-id"
```

Or export as environment variables (using bootstrap variables from earlier):
```bash
export TF_VAR_github_token="$GITHUB_TOKEN"
export TF_VAR_github_owner="$GITHUB_OWNER"
export TF_VAR_gcp_project_id="$PROJECT_ID"
export TF_VAR_github_app_id="YOUR_GITHUB_APP_ID"
```

### Step 2: Initialize and Apply

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file="terraform.tfvars"

# Apply the configuration
terraform apply -var-file="terraform.tfvars"
```

### Step 3: Set Up Google Cloud Resources

After applying, set up GitHub App secrets:

```bash
# View the setup commands
terraform output github_app_setup_commands

# View the automatically created infrastructure
terraform output infrastructure_summary

# View repository details with trigger IDs and scheduler jobs
terraform output repository_summary
```

### Step 3.5: Create Infrastructure Management Triggers (Now that repo exists)

After Terraform creates the infrastructure repository, now create the Cloud Build triggers:

```bash
# Connect your GitHub account to Cloud Build (if not already done)
# Go to: https://console.cloud.google.com/cloud-build/triggers/connect?project=$PROJECT_ID
# Choose "GitHub (Cloud Build GitHub App)" and authorize access to your organization

# Now create the triggers for the infrastructure repository
./setup/triggers.sh $PROJECT_ID $GITHUB_OWNER $REPO_NAME

# Verify triggers were created
gcloud builds triggers list --project=$PROJECT_ID
```

**Note**: If the trigger creation fails with "Repository not found", you may need to:
1. Go to Cloud Build > Triggers > Connect Repository
2. Connect your infrastructure repository manually first
3. Then run the trigger script

### Step 4: Create GitHub App and Add Secrets

After running `terraform apply`, you'll need to create a GitHub App and populate the secret values:

#### 4a. Create GitHub App (One-Time)
```bash
# Create GitHub App using manifest flow (manual step for now)
# Go to GitHub → Settings → Developer settings → GitHub Apps → New GitHub App
#
# App Settings:
# - Name: "SDK Automation for ${GITHUB_OWNER}"
# - Homepage URL: "https://github.com/${GITHUB_OWNER}"
# - Webhook URL: "https://example.com/webhook" (unused but required)
#
# Permissions:
# - Repository permissions → Contents: Write
# - Repository permissions → Pull requests: Write
# - Repository permissions → Metadata: Read
#
# Save the following values:
# - App ID (numeric, e.g., 123456)
# - Private Key (download the .pem file)
```

#### 4b. Install App on Repositories
```bash
# Install the GitHub App on each SDK repository
# Go to GitHub → Settings → Developer settings → GitHub Apps → "Your App" → Install App
# Select your organization and choose repositories:
# - python-sdk
# - go-sdk
# - databases-sdk
# - genai-sdk
#
# Note the installation ID for each repo (visible in URL after installation)
```

#### 4c. Add Secret Values (Automated Helper)
```bash
# Use the helper script to automatically discover installation IDs and generate commands
./modules/github-repo-with-cloudbuild/templates/installation-helper.sh generate-secrets $TF_VAR_github_app_id your-private-key.pem $PROJECT_ID "python-sdk go-sdk databases-sdk genai-sdk"

# Or manually add secrets:
# 1. Add GitHub App private key (shared secret)
cat your-app-private-key.pem | gcloud secrets versions add github-app-private-key --data-file=- --project=$PROJECT_ID

# 2. Find installation IDs using helper
./modules/github-repo-with-cloudbuild/templates/installation-helper.sh summary $TF_VAR_github_app_id your-private-key.pem

# 3. Add installation IDs (replace with actual IDs from step 2)
echo -n "123456789" | gcloud secrets versions add python-sdk-installation-id --data-file=- --project=$PROJECT_ID
echo -n "123456790" | gcloud secrets versions add go-sdk-installation-id --data-file=- --project=$PROJECT_ID
echo -n "123456791" | gcloud secrets versions add databases-sdk-installation-id --data-file=- --project=$PROJECT_ID
echo -n "123456792" | gcloud secrets versions add genai-sdk-installation-id --data-file=- --project=$PROJECT_ID
```

**Security Benefits**: Each repository gets repository-scoped tokens that automatically expire in 1 hour and cannot access other repositories.

### Expected Results

This will create four SDK repositories:

1. **python-sdk repository**:
   - Demo: Runs every 5 minutes (Production: 2:00 AM EST weekly)
   - Uses `python_sdk` secret from Secret Manager
   - Has specific CODEOWNERS for Python team, SDK team, and docs team
   - Uses auto-created `python-sdk-sa` service account

2. **go-sdk repository**:
   - Demo: Runs every 5 minutes (Production: 2:30 AM EST weekly)
   - Uses `go_sdk` secret from Secret Manager
   - Has specific CODEOWNERS for Go team, SDK team, and docs team
   - Uses auto-created `go-sdk-sa` service account

3. **databases-sdk repository**:
   - Demo: Runs every 5 minutes (Production: 1:30 AM PST weekly)
   - Uses `databases_sdk` secret from Secret Manager
   - Has specific CODEOWNERS for database team and SDK team
   - Uses auto-created `databases-sdk-sa` service account

4. **genai-sdk repository**:
   - Demo: Runs every 5 minutes (Production: 3:00 AM EST weekly)
   - Uses `genai_sdk` secret from Secret Manager
   - Has specific CODEOWNERS for AI team and docs team
   - Uses auto-created `genai-sdk-sa` service account

All SDK repositories will include:
- Cloud Build configuration (`cloudbuild.yaml`)
- Demo automation script (`scripts/update.sh`)
- CODEOWNERS protection for all CI/CD files
- Branch protection on the main branch
- **Automated Cloud Build triggers** (created by Terraform)
- **Automated Cloud Scheduler jobs** (created by Terraform, demo: every 5 minutes)
- **Automated Pub/Sub topics** (created by Terraform)
- **Automated service accounts** (created by Terraform with appropriate permissions)

### Cleanup

To remove all created resources:
```bash
terraform destroy -var-file="terraform.tfvars"
```

## Self-Managing Infrastructure Setup

For the repository containing this module itself, you need to manually create the Cloud Build triggers for self-management:

```bash
# Create the trigger for the SDK module repository (main branch)
gcloud builds triggers create github \
  --repo-name=$REPO_NAME \
  --repo-owner=$GITHUB_OWNER \
  --branch-pattern=^main$ \
  --build-config=cloudbuild.yaml \
  --name=terraform-sdk-module-auto-apply \
  --description="Auto-apply Terraform changes for SDK repository management module" \
  --service-account=terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID

# Also create trigger for pull requests (plan only)
gcloud builds triggers create github \
  --repo-name=$REPO_NAME \
  --repo-owner=$GITHUB_OWNER \
  --pull-request-pattern=^main$ \
  --build-config=cloudbuild-pr.yaml \
  --name=terraform-sdk-module-pr-plan \
  --description="Terraform plan for SDK repository management pull requests" \
  --service-account=terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com \
  --project=$PROJECT_ID
```

**Note**: These triggers are only needed for the infrastructure management repository itself. All SDK repository triggers are created automatically by Terraform.

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

### Manual Infrastructure Management Service Account Setup

**Note**: This is only needed once for the infrastructure management. Repository-specific service accounts are created automatically.

Create the service account for Terraform automation:

```bash
# Create service account for SDK Terraform automation
gcloud iam service-accounts create terraform-automation \
  --display-name="SDK Terraform Automation Service Account" \
  --description="Service account for automated SDK repository Terraform deployments" \
  --project=$PROJECT_ID

# Grant necessary permissions
SA_EMAIL="terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com"

# Cloud Build permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/cloudbuild.builds.builder"

# Secret Manager permissions (to read GitHub token)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/secretmanager.secretAccessor"

# Storage permissions (for Terraform state)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.admin"

# IAM permissions (to manage service accounts created by the module)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/resourcemanager.projectIamAdmin"
```

## Secret Setup

Store the GitHub token in Secret Manager:

```bash
# Create secret for GitHub token
echo "$GITHUB_TOKEN" | gcloud secrets create github-token \
  --data-file=- \
  --project=$PROJECT_ID

# Grant access to the service account
gcloud secrets add-iam-policy-binding github-token \
  --member="serviceAccount:terraform-automation@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor" \
  --project=$PROJECT_ID
```

Now when you push changes to the main branch, Cloud Build will automatically:
1. Validate your Terraform syntax
2. Plan the changes
3. Apply the changes to create/update SDK GitHub repositories
4. Output the results and next steps for manual GCP setup

---

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
- **Cloud Build Triggers**: Automatically created for each SDK repository
- **Cloud Scheduler Jobs**: Automatically configured for weekly execution
- **Pub/Sub Topics**: Automatically created for trigger communication
- **Full Integration**: All components are properly linked with dependencies
The only manual step remaining is creating secrets in Secret Manager for security reasons.

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