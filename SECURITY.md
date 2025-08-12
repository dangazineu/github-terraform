# Security Guide

This document covers security procedures for the SDK automation infrastructure.

## GitHub App Private Key Rotation

### When to Rotate Keys

Rotate the GitHub App private key immediately in these situations:
- ✅ **Key exposed in code repository** (like git commits, PRs)
- ✅ **Key exposed in logs or error messages**
- ✅ **Suspected unauthorized access to key**
- ✅ **Team member with key access leaves**
- ✅ **Regular security rotation** (recommended: every 90 days)

### Automated Rotation Process

Use the provided script for safe, guided key rotation:

```bash
./rotate-github-app-key.sh
```

This script will:
1. Check prerequisites (gcloud auth, project access)
2. Create a backup of the current key
3. Guide you through manual GitHub steps
4. Update Google Secret Manager
5. Test the new key
6. Trigger infrastructure rebuild
7. Clean up temporary files

### Manual Steps (Performed via GitHub Web UI)

The script will guide you through these manual steps:

#### 1. Access GitHub App Settings
- Go to: https://github.com/settings/apps/sdk-automation-for-dg-ghtest
- Or navigate: GitHub Settings → Developer settings → GitHub Apps → sdk-automation-for-dg-ghtest

#### 2. Generate New Private Key
- Scroll to "Private keys" section
- Click **"Generate a private key"**
- 🔒 **Important**: This automatically **revokes the old key**
- Download the .pem file (e.g., `sdk-automation-for-dg-ghtest.2025-08-13.private-key.pem`)

#### 3. Verify App Permissions
While in the GitHub App settings, verify these permissions are still correct:
- **Repository permissions**:
  - Contents: Write (for creating/updating files)
  - Pull requests: Write (for creating PRs)
  - Metadata: Read (for repository info)
- **Account permissions**: None required

### Emergency Key Rotation (Manual Process)

If the automation script is unavailable, follow these manual steps:

#### 1. Generate New Key (Manual)
Follow the manual steps above to generate a new key in GitHub.

#### 2. Update Secret Manager (Manual)
```bash
# Replace with your actual key file path
cat /path/to/new-private-key.pem | gcloud secrets versions add github-app-private-key --data-file=- --project=dgzn-terraform

# Verify the update
gcloud secrets versions list github-app-private-key --project=dgzn-terraform
```

#### 3. Test the New Key (Manual)
```bash
# Use the installation helper to test
./modules/github-repo-with-cloudbuild/templates/installation-helper.sh test-key 1770057 /path/to/new-private-key.pem

# Or test with a manual build trigger
gcloud builds triggers run infra-main-apply --branch=main --project=dgzn-terraform
```

### Verification Steps

After rotation, verify the system works:

1. **Check Cloud Build**: Monitor for successful builds
   - https://console.cloud.google.com/cloud-build/builds?project=dgzn-terraform

2. **Check SDK Automation**: Wait for next scheduled run (every 5 minutes)
   - Look for new PRs in SDK repositories
   - Check Cloud Build logs for authentication success

3. **Test Manual Trigger** (optional):
   ```bash
   # Trigger a manual automation run
   gcloud pubsub topics publish sdk-automation-triggers --message='{"repository":"python-sdk"}' --project=dgzn-terraform
   ```

## Security Best Practices

### For Repository Management

- ✅ **Never commit private keys** to git repositories
- ✅ **Use .gitignore** for `*.pem`, `*.key`, `*.private-key.*`
- ✅ **Review PRs carefully** for accidentally committed secrets
- ✅ **Use branch protection** on main branches

### For Secret Management

- ✅ **Use Google Secret Manager** for all sensitive data
- ✅ **Principle of least privilege** for service account permissions
- ✅ **Regular key rotation** (90-day cycles recommended)
- ✅ **Monitor secret access** through Cloud Logging

### For GitHub Apps

- ✅ **Minimal permissions** - only grant what's needed
- ✅ **Organization-level installation** for better control
- ✅ **Regular permission audits**
- ✅ **Monitor app activity** through GitHub audit logs

## Incident Response

### If a Private Key is Exposed

1. **Immediate Action** (within 15 minutes):
   ```bash
   ./rotate-github-app-key.sh
   ```

2. **Document the Incident**:
   - When was it exposed?
   - How was it exposed? (commit, PR, logs, etc.)
   - What systems had access?
   - How long was it exposed?

3. **Clean Up Exposure**:
   - Remove from git history (if committed)
   - Contact GitHub Support for PR cleanup (if needed)
   - Clear logs that may contain the key
   - Notify team members

4. **Monitor for Unauthorized Use**:
   - Check GitHub audit logs
   - Monitor Cloud Build for unexpected activity
   - Review SDK repositories for unauthorized changes

### GitHub Support Contact

For removing sensitive data from GitHub (PR histories, etc.):

1. Go to: https://support.github.com/contact/private-information
2. Select "I need to remove sensitive data"
3. Provide:
   - Repository URL
   - PR/commit URLs containing sensitive data
   - Description: "Private key for GitHub App accidentally committed"

## Monitoring and Alerting

### Set Up Alerts (Recommended)

1. **Failed Authentication Alerts**:
   ```bash
   # Set up Cloud Monitoring alert for failed GitHub API calls
   # Filter: "401 Unauthorized" in Cloud Build logs
   ```

2. **Unexpected Secret Access**:
   ```bash
   # Monitor secret access patterns
   # Alert on access from unexpected service accounts
   ```

3. **Build Failure Alerts**:
   ```bash
   # Alert on consecutive build failures
   # May indicate authentication issues
   ```

## Recovery Procedures

### If Automation Stops Working

1. **Check recent changes**:
   - Recent commits to infra repository
   - Recent secret rotations
   - Recent permission changes

2. **Verify authentication**:
   ```bash
   # Test current key
   ./modules/github-repo-with-cloudbuild/templates/installation-helper.sh test-key 1770057 /tmp/current-key.pem
   ```

3. **Check service account permissions**:
   ```bash
   # Re-run setup to ensure all permissions
   ./setup/service-accounts.sh dgzn-terraform
   ```

### If Secret Manager is Compromised

1. **Rotate all keys immediately**
2. **Audit all secret access logs**
3. **Review and update service account permissions**
4. **Consider changing GitHub App if necessary**

## Contact Information

- **Security Issues**: Create issue in this repository with `security` label
- **Emergency Contact**: [Your team contact information]
- **GitHub Support**: https://support.github.com/contact/private-information