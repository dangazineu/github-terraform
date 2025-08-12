terraform {
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

# Create repo-specific service account
resource "google_service_account" "repo_sa" {
  project      = var.gcp_project_id
  account_id   = "${var.repo_name}-sa"
  display_name = "Service Account for ${var.repo_name} SDK"
  description  = "Service account for automated operations in ${var.repo_name} repository"
}

# Grant Cloud Build permissions to the service account
resource "google_project_iam_member" "repo_sa_cloudbuild" {
  project = var.gcp_project_id
  role    = "roles/cloudbuild.builds.builder"
  member  = "serviceAccount:${google_service_account.repo_sa.email}"
}

# Grant Secret Manager access to shared GitHub App private key
resource "google_secret_manager_secret_iam_member" "repo_sa_private_key_access" {
  project   = var.gcp_project_id
  secret_id = var.github_app_private_key_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.repo_sa.email}"
}

# Grant Secret Manager access to repository-specific installation ID
resource "google_secret_manager_secret_iam_member" "repo_sa_installation_access" {
  project   = var.gcp_project_id
  secret_id = local.installation_id_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.repo_sa.email}"
}

# Create the GitHub repository
resource "github_repository" "repo" {
  name        = var.repo_name
  description = var.repo_description
  visibility  = "private"

  # Enable issues and wiki if needed
  has_issues = true
  has_wiki   = false

  # Auto-init with README
  auto_init = true

  # Enable branch protection and require reviews
  # This works in conjunction with CODEOWNERS
}

# Enable branch protection for main branch
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.name
  pattern       = "main"

  # Require pull request reviews
  required_pull_request_reviews {
    required_approving_review_count = 1
    require_code_owner_reviews      = true
    dismiss_stale_reviews          = true
    restrict_dismissals            = false
  }

  # Require status checks to pass
  required_status_checks {
    strict = true
    contexts = []
  }

  # Enforce restrictions for administrators
  enforce_admins = false

  # Allow force pushes and deletions for administrators
  allows_force_pushes = false
  allows_deletions   = false
}

# Create CODEOWNERS file to protect Cloud Build configuration
resource "github_repository_file" "codeowners" {
  repository = github_repository.repo.name
  file       = ".github/CODEOWNERS"
  content = templatefile("${path.module}/templates/CODEOWNERS.tpl", {
    codeowners_team      = var.codeowners_team
    additional_codeowners = var.additional_codeowners
  })

  commit_message = "Add CODEOWNERS file to protect Cloud Build configuration"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}

# Create the Cloud Build configuration file
resource "github_repository_file" "cloudbuild_config" {
  repository = github_repository.repo.name
  file       = "cloudbuild.yaml"
  content = templatefile("${path.module}/templates/cloudbuild.yaml.tpl", {
    gcp_project_id                    = var.gcp_project_id
    github_app_private_key_secret_name = var.github_app_private_key_secret_name
    installation_id_secret_name       = local.installation_id_secret_name
    github_app_id                     = var.github_app_id
    repo_name                         = var.repo_name
    github_owner                      = var.github_owner
  })

  commit_message = "Add Cloud Build configuration via Terraform"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}

# Create the main automation script
resource "github_repository_file" "update_script" {
  repository = github_repository.repo.name
  file       = "scripts/update.sh"
  content    = file("${path.module}/templates/update.sh")

  commit_message = "Add update script via Terraform"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}

# Create JWT utilities script
resource "github_repository_file" "jwt_utils_script" {
  repository = github_repository.repo.name
  file       = "scripts/jwt-utils.sh"
  content    = file("${path.module}/templates/jwt-utils.sh")

  commit_message = "Add JWT utilities via Terraform"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}

# Create installation helper script
resource "github_repository_file" "installation_helper_script" {
  repository = github_repository.repo.name
  file       = "scripts/installation-helper.sh"
  content    = file("${path.module}/templates/installation-helper.sh")

  commit_message = "Add installation helper via Terraform"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}

# Create health check script
resource "github_repository_file" "health_check_script" {
  repository = github_repository.repo.name
  file       = "scripts/health-check.sh"
  content    = file("${path.module}/templates/health-check.sh")

  commit_message = "Add health check script via Terraform"
  commit_author  = "terraform-automation"
  commit_email   = "terraform@yourcompany.com"

  overwrite_on_create = true
}


# Create Cloud Build trigger for the repository
resource "google_cloudbuild_trigger" "repo_trigger" {
  project     = var.gcp_project_id
  name        = "${var.repo_name}-weekly-trigger"
  description = "Weekly scheduled build for ${var.repo_name} SDK"

  github {
    owner = var.github_owner
    name  = var.repo_name
    push {
      branch = "^main$"
    }
  }

  filename = "cloudbuild.yaml"

  service_account = google_service_account.repo_sa.email

  depends_on = [
    github_repository_file.cloudbuild_config,
    github_repository_file.update_script,
    github_repository_file.jwt_utils_script,
    github_repository_file.installation_helper_script,
    github_repository_file.health_check_script
  ]
}


# Create Cloud Scheduler job for demo execution (every 5 minutes)
# Production schedule would be: "0 ${split(":", var.schedule_time)[1]} ${split(":", var.schedule_time)[0]} * * 0"
resource "google_cloud_scheduler_job" "demo_trigger" {
  project     = var.gcp_project_id
  name        = "${var.repo_name}-demo-schedule"
  description = "Demo trigger for ${var.repo_name} SDK automation (every 5 minutes)"
  region      = var.scheduler_region
  
  schedule  = "*/5 * * * *"  # Demo: every 5 minutes
  time_zone = var.schedule_timezone

  pubsub_target {
    topic_name = var.pubsub_topic_name
    data = base64encode(jsonencode({
      projectId  = var.gcp_project_id
      triggerId  = google_cloudbuild_trigger.repo_trigger.trigger_id
    }))
  }

  depends_on = [
    google_cloudbuild_trigger.repo_trigger
  ]
}