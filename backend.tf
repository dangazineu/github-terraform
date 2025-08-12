# backend.tf - Terraform backend configuration
terraform {
  backend "gcs" {
    bucket = "dgzn-terraform-tfstate" # Project-specific bucket name
    prefix = "github-cloudbuild-module"
  }
}