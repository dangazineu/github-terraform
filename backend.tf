# backend.tf - Terraform backend configuration
terraform {
  backend "gcs" {
    bucket = "my-terraform-state-bucket"  # Replace with your bucket name
    prefix = "github-cloudbuild-module"
  }
}