variable "repo_name" {
  description = "Name of the GitHub repository"
  type        = string
}

variable "repo_description" {
  description = "Description of the GitHub repository"
  type        = string
  default     = ""
}

variable "gcp_project_id" {
  description = "Google Cloud Project ID"
  type        = string
}


variable "github_owner" {
  description = "GitHub organization or username"
  type        = string
}

variable "secret_name_suffix" {
  description = "Suffix for the secret name (defaults to repo name)"
  type        = string
  default     = ""
}

variable "schedule_timezone" {
  description = "Timezone for the schedule"
  type        = string
  default     = "UTC"
}

variable "schedule_time" {
  description = "Time of day to run (format: HH:MM)"
  type        = string
  default     = "02:00"
}

variable "codeowners_team" {
  description = "GitHub team that should approve changes to Cloud Build files (format: @org/team-name)"
  type        = string
}

variable "additional_codeowners" {
  description = "Additional CODEOWNERS rules for the repository"
  type        = list(string)
  default     = []
}

variable "scheduler_region" {
  description = "Google Cloud region for Cloud Scheduler job"
  type        = string
  default     = "us-central1"
}

variable "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic for Cloud Build triggers"
  type        = string
}

variable "github_app_private_key_secret_name" {
  description = "Name of the secret containing the GitHub App private key"
  type        = string
  default     = "github-app-private-key"
}

variable "github_app_id" {
  description = "GitHub App ID (numeric)"
  type        = string
}