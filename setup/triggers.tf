# Terraform configuration for creating Cloud Build triggers
# This is a one-time setup file for infrastructure repository triggers

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# Variables for the trigger setup
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "github_owner" {
  description = "GitHub organization or user"
  type        = string
}

variable "repo_name" {
  description = "Repository name"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "connection_name" {
  description = "GitHub connection name"
  type        = string
  default     = "my-github-connection"
}

variable "service_account_email" {
  description = "Service account email for triggers"
  type        = string
}

# Configure the Google Cloud Provider
provider "google" {
  project = var.project_id
  region  = var.region
}

# Cloud Build trigger for main branch (auto-apply) using legacy GitHub App
resource "google_cloudbuild_trigger" "main_branch_trigger" {
  name     = "${var.repo_name}-main-apply"
  project  = var.project_id
  # NOTE: No location - 1st gen GitHub connections are global

  github {
    owner = var.github_owner
    name  = var.repo_name
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"

  description = "Auto-apply Terraform changes for main branch"

  tags = ["infrastructure", "main-branch", "auto-apply"]
}

# Cloud Build trigger for pull requests (plan only) using legacy GitHub App
resource "google_cloudbuild_trigger" "pr_trigger" {
  name     = "${var.repo_name}-pr-plan"
  project  = var.project_id
  # NOTE: No location - 1st gen GitHub connections are global

  github {
    owner = var.github_owner
    name  = var.repo_name
    pull_request {
      branch = "^main$"
    }
  }

  filename = "cloudbuild-pr.yaml"

  service_account = "projects/${var.project_id}/serviceAccounts/${var.service_account_email}"

  description = "Run Terraform plan for pull requests"

  tags = ["infrastructure", "pull-request", "plan"]
}

# Outputs
output "main_trigger_id" {
  description = "ID of the main branch trigger"
  value       = google_cloudbuild_trigger.main_branch_trigger.trigger_id
}

output "pr_trigger_id" {
  description = "ID of the pull request trigger"
  value       = google_cloudbuild_trigger.pr_trigger.trigger_id
}

output "main_trigger_name" {
  description = "Name of the main branch trigger"
  value       = google_cloudbuild_trigger.main_branch_trigger.name
}

output "pr_trigger_name" {
  description = "Name of the pull request trigger"
  value       = google_cloudbuild_trigger.pr_trigger.name
}