steps:
  # Step 1: Health check (validate GitHub App authentication)
  - name: 'gcr.io/cloud-builders/git'
    id: 'health-check'
    entrypoint: 'bash'
    args:
      - './scripts/health-check.sh'
    env:
      - 'PROJECT_ID=${gcp_project_id}'
      - 'GITHUB_APP_ID=${github_app_id}'
      - 'GITHUB_APP_PRIVATE_KEY_SECRET=${github_app_private_key_secret_name}'
      - 'INSTALLATION_ID_SECRET=${installation_id_secret_name}'
      - 'GITHUB_REPOSITORY=${github_owner}/${repo_name}'
      - 'GITHUB_REPOSITORY_OWNER=${github_owner}'

  # Step 2: Run the GitHub App PR automation script
  - name: 'gcr.io/cloud-builders/git'
    id: 'run-github-app-automation'
    entrypoint: 'bash'
    args:
      - './scripts/update.sh'
    env:
      - 'PROJECT_ID=${gcp_project_id}'
      - 'GITHUB_APP_ID=${github_app_id}'
      - 'GITHUB_APP_PRIVATE_KEY_SECRET=${github_app_private_key_secret_name}'
      - 'INSTALLATION_ID_SECRET=${installation_id_secret_name}'
      - 'GITHUB_REPOSITORY=${github_owner}/${repo_name}'
      - 'GITHUB_REPOSITORY_OWNER=${github_owner}'

# Service account configuration
serviceAccount: '${service_account_email}'

# Logging configuration
options:
  logging: CLOUD_LOGGING_ONLY
  logStreamingOption: STREAM_ON

# Timeout (30 minutes)
timeout: '1800s'