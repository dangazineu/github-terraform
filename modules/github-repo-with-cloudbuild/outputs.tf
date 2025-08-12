output "repository_name" {
  description = "Name of the created repository"
  value       = github_repository.repo.name
}

output "repository_full_name" {
  description = "Full name of the repository"
  value       = github_repository.repo.full_name
}

output "repository_url" {
  description = "URL of the repository"
  value       = github_repository.repo.html_url
}

output "secret_name" {
  description = "Name of the secret that should be stored in Secret Manager (legacy compatibility)"
  value       = local.secret_name_formatted
}

output "installation_id_secret_name" {
  description = "Name of the secret for storing this repository's GitHub App installation ID"
  value       = local.installation_id_secret_name
}

output "cloud_build_trigger_id" {
  description = "ID of the created Cloud Build trigger"
  value       = google_cloudbuild_trigger.repo_trigger.trigger_id
}

output "cloud_scheduler_job_name" {
  description = "Name of the created Cloud Scheduler job"
  value       = google_cloud_scheduler_job.demo_trigger.name
}

output "service_account_email" {
  description = "Email of the created service account"
  value       = google_service_account.repo_sa.email
}

output "github_app_private_key_secret_name" {
  description = "Name of the shared GitHub App private key secret"
  value       = var.github_app_private_key_secret_name
}

output "github_app_id" {
  description = "GitHub App ID used by this repository"
  value       = var.github_app_id
}