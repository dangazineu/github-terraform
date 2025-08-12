locals {
  # GitHub App installation ID secret name for this repository
  installation_id_secret_name = "${var.repo_name}-installation-id"
  
  # Legacy secret name (kept for outputs compatibility)
  secret_name = var.secret_name_suffix != "" ? var.secret_name_suffix : var.repo_name
  secret_name_formatted = replace(local.secret_name, "-", "_")
}