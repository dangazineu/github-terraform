terraform {
  required_version = ">= 1.0"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure the GitHub provider
provider "github" {
  token = var.github_token
}

# Configure the Google provider
provider "google" {
  project = var.gcp_project_id
}

# Input variables
variable "github_token" {
  description = "GitHub personal access token with repo permissions"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or username for SDK repositories"
  type        = string
}

variable "gcp_project_id" {
  description = "Google Cloud Project ID for SDK infrastructure"
  type        = string
}

variable "scheduler_region" {
  description = "Google Cloud region for Cloud Scheduler jobs"
  type        = string
  default     = "us-central1"
}

variable "github_app_id" {
  description = "Cloud Build GitHub App ID (for connecting repositories to Cloud Build)"
  type        = string
}

variable "sdk_automation_github_app_id" {
  description = "SDK Automation GitHub App ID (for PR automation scripts)"
  type        = string
}

# Repository configurations
locals {
  # Common DevOps team for all repositories
  devops_team = "@${var.github_owner}/devops-team"

  # SDK repository configurations
  repositories = {
    # Python SDK repository
    "python-sdk" = {
      description       = "Python SDK with automated package publishing and API token rotation"
      schedule_time     = "02:00" # 2 AM EST
      schedule_timezone = "America/New_York"
      additional_owners = [
        "*.py @${var.github_owner}/python-team",
        "pyproject.toml @${var.github_owner}/sdk-team",
        "setup.py @${var.github_owner}/sdk-team",
        "docs/ @${var.github_owner}/docs-team"
      ]
    }

    # Go SDK repository
    "go-sdk" = {
      description       = "Go SDK with automated module publishing and dependency updates"
      schedule_time     = "02:30" # 2:30 AM EST
      schedule_timezone = "America/New_York"
      additional_owners = [
        "*.go @${var.github_owner}/go-team",
        "go.mod @${var.github_owner}/sdk-team",
        "go.sum @${var.github_owner}/sdk-team",
        "examples/ @${var.github_owner}/docs-team"
      ]
    }

    # Database SDK repository
    "databases-sdk" = {
      description       = "Multi-language SDK for database integrations with connection management"
      schedule_time     = "01:30" # 1:30 AM PST
      schedule_timezone = "America/Los_Angeles"
      additional_owners = [
        "*/database/ @${var.github_owner}/database-team",
        "*.sql @${var.github_owner}/database-team",
        "migrations/ @${var.github_owner}/database-team",
        "connectors/ @${var.github_owner}/sdk-team"
      ]
    }

    # Generative AI SDK repository
    "genai-sdk" = {
      description       = "Generative AI SDK with model access tokens and API key management"
      schedule_time     = "03:00" # 3 AM EST
      schedule_timezone = "America/New_York"
      additional_owners = [
        "*/models/ @${var.github_owner}/ai-team",
        "*/training/ @${var.github_owner}/ai-team",
        "*/inference/ @${var.github_owner}/ai-team",
        "notebooks/ @${var.github_owner}/docs-team"
      ]
    }

    # Test SDK repository
    "test-sdk" = {
      description       = "test AI SDK"
      schedule_time     = "03:00" # 3 AM EST
      schedule_timezone = "America/New_York"
      additional_owners = [
        "*/models/ @${var.github_owner}/sdk-team",
        "*/training/ @${var.github_owner}/sdk-team",
        "*/inference/ @${var.github_owner}/sdk-team",
        "notebooks/ @${var.github_owner}/docs-team"
      ]
    }
}

# Create shared Pub/Sub topic for Cloud Build triggers
resource "google_pubsub_topic" "sdk_automation" {
  project = var.gcp_project_id
  name    = "sdk-automation-triggers"
}

# Create shared GitHub App private key secret
resource "google_secret_manager_secret" "github_app_private_key" {
  project   = var.gcp_project_id
  secret_id = "github-app-private-key"

  replication {
    auto {}
  }
}

# Create installation ID secrets for each repository
resource "google_secret_manager_secret" "installation_ids" {
  for_each  = local.repositories
  project   = var.gcp_project_id
  secret_id = "${each.key}-installation-id"

  replication {
    auto {}
  }
}

# Create repositories using the module
module "github_repos" {
  source = "./modules/github-repo-with-cloudbuild"

  for_each = local.repositories

  # Repository configuration
  repo_name        = each.key
  repo_description = each.value.description
  github_owner     = var.github_owner

  # Google Cloud configuration
  gcp_project_id = var.gcp_project_id

  # GitHub App configuration
  github_app_id                      = var.sdk_automation_github_app_id
  github_app_private_key_secret_name = google_secret_manager_secret.github_app_private_key.secret_id

  # Scheduling configuration
  schedule_time     = each.value.schedule_time
  schedule_timezone = each.value.schedule_timezone

  # CODEOWNERS configuration
  codeowners_team       = local.devops_team
  additional_codeowners = each.value.additional_owners

  # Cloud infrastructure configuration
  scheduler_region  = var.scheduler_region
  pubsub_topic_name = google_pubsub_topic.sdk_automation.id
}

# Outputs
output "repository_summary" {
  description = "Summary of created SDK repositories with full automation"
  value = {
    for repo_key, repo_config in local.repositories : repo_key => {
      repository_name        = module.github_repos[repo_key].repository_name
      repository_url         = module.github_repos[repo_key].repository_url
      secret_name            = module.github_repos[repo_key].secret_name
      service_account        = module.github_repos[repo_key].service_account_email
      schedule_time          = "${repo_config.schedule_time} ${repo_config.schedule_timezone}"
      cloud_build_trigger_id = module.github_repos[repo_key].cloud_build_trigger_id
      scheduler_job_name     = module.github_repos[repo_key].cloud_scheduler_job_name
    }
  }
}

output "github_app_setup_commands" {
  description = "Commands to populate GitHub App secrets in Secret Manager"
  value = {
    private_key_command = "cat your-github-app-private-key.pem | gcloud secrets versions add ${google_secret_manager_secret.github_app_private_key.secret_id} --data-file=- --project=${var.gcp_project_id}"
    installation_id_commands = [
      for repo_key in keys(local.repositories) :
      "echo -n \"INSTALLATION_ID_FOR_${upper(replace(repo_key, "-", "_"))}\" | gcloud secrets versions add ${google_secret_manager_secret.installation_ids[repo_key].secret_id} --data-file=- --project=${var.gcp_project_id}"
    ]
    helper_script = "./modules/github-repo-with-cloudbuild/templates/installation-helper.sh generate-secrets ${var.sdk_automation_github_app_id} your-private-key.pem ${var.gcp_project_id} '${join(" ", keys(local.repositories))}'"
  }
}

output "infrastructure_summary" {
  description = "Summary of automatically created infrastructure"
  value = {
    repositories_created = length(local.repositories)
    cloud_build_triggers = [
      for repo_key in keys(local.repositories) :
      "Trigger ID: ${module.github_repos[repo_key].cloud_build_trigger_id} for ${repo_key}"
    ]
    scheduler_jobs = [
      for repo_key in keys(local.repositories) :
      "Job: ${module.github_repos[repo_key].cloud_scheduler_job_name} for ${repo_key}"
    ]
    pubsub_topic = google_pubsub_topic.sdk_automation.name
  }
}
