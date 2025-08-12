# CODEOWNERS file - Defines code ownership and review requirements for SDK repository
# This file is managed by Terraform - do not edit manually

# Cloud Build and CI/CD configuration files require approval from the DevOps team
cloudbuild.yaml ${codeowners_team}
trigger.yaml ${codeowners_team}
scripts/update.sh ${codeowners_team}

# Terraform-managed files require approval from the DevOps team
.github/CODEOWNERS ${codeowners_team}

# Any files in .github directory (workflows, templates, etc.)
.github/ ${codeowners_team}

%{~ if length(additional_codeowners) > 0 ~}
# Additional code ownership rules
%{~ for rule in additional_codeowners ~}
${rule}
%{~ endfor ~}
%{~ endif ~}