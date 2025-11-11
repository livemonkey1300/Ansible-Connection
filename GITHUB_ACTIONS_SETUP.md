# GitHub Actions Setup for Ansible Deployment

## Required Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add these secrets:

### SSH Keys
- `ANSIBLE_SSH_PRIVATE_KEY`: Your private SSH key for Ansible connections
- `STAGING_SSH_KEY`: SSH key for staging environment (if different)
- `PRODUCTION_SSH_KEY`: SSH key for production environment (if different)

### Target Hosts  
- `TARGET_HOST`: Default target host(s) - space separated if multiple
- `STAGING_HOST`: Staging server hostname or IP
- `PRODUCTION_HOST`: Production server hostname or IP

### Optional Secrets
- `ANSIBLE_VAULT_PASSWORD`: Password for Ansible Vault (if using encrypted vars)

## Workflow Files Created

1. **`.github/workflows/ansible-deploy.yml`** - Main deployment workflow with:
   - Ansible linting and validation
   - Security scanning with Trivy
   - Dry run for pull requests
   - Full deployment for pushes

2. **`.github/workflows/environment-deploy.yml`** - Reusable workflow template

3. **`.github/workflows/deploy-environments.yml`** - Environment-specific deployments

## How to Use

### Automatic Deployments
- Push to `develop` branch → deploys to staging
- Push to `main` branch → deploys to production  

### Manual Deployments
- Go to Actions tab → "Ansible Deploy" → "Run workflow"
- Select environment and playbook to run

### Pull Request Testing
- Creates PR → runs dry-run deployment with `--check --diff`

## SSH Key Setup

Generate and configure SSH keys:

```bash
# Generate new SSH key for Ansible
ssh-keygen -t rsa -b 4096 -f ~/.ssh/ansible_key -C "ansible@github-actions"

# Copy public key to target servers
ssh-copy-id -i ~/.ssh/ansible_key.pub user@your-server

# Add private key content to GitHub secrets
cat ~/.ssh/ansible_key
```

## Environment Configuration

Create environment-specific configurations in GitHub:
1. Go to Settings → Environments
2. Create `staging` and `production` environments
3. Add protection rules if needed (approvals, restricted branches)

## Testing the Setup

1. Push changes to trigger workflow
2. Check Actions tab for workflow status
3. Review logs for any issues
4. Verify deployment on target servers

## Troubleshooting

- Check SSH connectivity in workflow logs
- Verify inventory script is executable
- Ensure secrets are properly configured
- Check Ansible syntax with local linting