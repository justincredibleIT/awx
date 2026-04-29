# awx

setup credentials.yml with
vault_gitlab_token
vault_gitlab_ssh_private_key_path
vault_gitlab_ssh_public_key

# Add a User (with access level name and optional expiry)

ansible-playbook playbooks/gitlab-config-all-defined.yml \
  --ask-vault-pass \
  -e "target_scope=administration/experiments/jv-test-project" \
  -e "target_user=newuser" \
  -e "target_action=add" \
  -e "target_access_level=Developer" \
  -e "target_expiry=2027-06-30"

target_access_level: Guest, Reporter, Developer, Maintainer, or Owner
target_expiry: Optional, format YYYY-MM-DD

# Remove a User

ansible-playbook playbooks/gitlab-config-all-defined.yml \
  --ask-vault-pass \
  -e "target_scope=administration/experiments/jv-test-project" \
  -e "target_user=newuser" \
  -e "target_action=remove"

No other parameters needed
User is completely removed from the project  

# Update User's Expiry Date (preserves access level)

ansible-playbook playbooks/gitlab-config-all-defined.yml \
  --ask-vault-pass \
  -e "target_scope=administration/experiments/jv-test-project" \
  -e "target_user=username" \
  -e "target_action=update-expiry" \
  -e "target_expiry=2026-12-31"

Keeps existing access level (Maintainer) intact
Only requires username, project, and new date  

# New project

ansible-playbook playbooks/gitlab-config-all-defined.yml \
  --ask-vault-pass \
  -e "target_scope=administration/experiments/new-project" \
  -e "target_user=username" \
  -e "target_action=add" \
  -e "target_access_level=Developer" \
  -e "target_expiry=2026-05-01" \
  -e "run_provision=true"