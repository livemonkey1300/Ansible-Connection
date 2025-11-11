# Terraform GitHub Actions Setup

## Overview
The Terraform workflows provide automated infrastructure deployment with these features:
- **Validation**: Format checking and security scanning
- **Planning**: Generate and review Terraform plans
- **Deployment**: Apply infrastructure changes
- **Integration**: Seamless handoff to Ansible for configuration

## Workflow Files

### 1. `terraform-deploy.yml` - Core Terraform Operations
- **Triggers**: Push to main/develop, PR, manual dispatch
- **Jobs**:
  - `terraform-validate`: Format check, init, and validate
  - `terraform-security`: Checkov security scanning
  - `terraform-plan`: Generate execution plans
  - `terraform-apply`: Apply changes (manual/main branch)
  - `terraform-destroy`: Destroy infrastructure (manual only)

### 2. `infrastructure-deploy.yml` - Combined Terraform + Ansible
- **Purpose**: End-to-end infrastructure provisioning and configuration
- **Flow**: Terraform → Extract outputs → Ansible deployment
- **Benefits**: Fully automated infrastructure lifecycle

## Required GitHub Secrets

### Terraform Cloud/Enterprise
```
TF_API_TOKEN: Your Terraform Cloud API token
```

### Provider Credentials
```
DIGITALOCEAN_TOKEN: DigitalOcean API token
VAULT_ADDR: HashiCorp Vault server address
VAULT_TOKEN: Vault authentication token
```

### Ansible Integration (for combined workflow)
```
ANSIBLE_SSH_PRIVATE_KEY: SSH key for server access
ANSIBLE_VAULT_PASSWORD: Vault password (optional)
```

## Terraform Cloud Configuration

Your `main.tf` is configured for Terraform Cloud:
```hcl
terraform {
  cloud {
    organization = "gcp-live"
    workspaces {
      name = "ansible-connection-staging"
    }
  }
}
```

### Setup Steps:
1. **Create Terraform Cloud account** at https://cloud.hashicorp.com/
2. **Create organization** named `gcp-live`
3. **Create workspace** named `ansible-connection-staging`
4. **Generate API token** in User Settings → Tokens
5. **Add token to GitHub secrets** as `TF_API_TOKEN`

## Environment Configuration

### Directory Structure
```
terraform/
├── staging/
│   └── main.tf          # Staging environment config
└── production/          # Optional production environment
    └── main.tf
```

### Provider Setup
The workflow supports multiple providers:
- **DigitalOcean**: For cloud infrastructure
- **Vault**: For secret management

## Usage Examples

### Automatic Deployments
```bash
# Deploy staging on develop branch push
git checkout develop
git push origin develop

# Deploy production on main branch push  
git checkout main
git push origin main
```

### Manual Deployments
1. Go to **Actions** → **Terraform Deploy** → **Run workflow**
2. Select:
   - Environment: `staging` or `production`
   - Action: `plan`, `apply`, or `destroy`

### Pull Request Flow
1. Create PR with Terraform changes
2. Automatic validation and security scanning
3. Plan posted as PR comment
4. Review and merge to apply changes

## Integration with Ansible

The `infrastructure-deploy.yml` workflow:
1. **Runs Terraform** to provision infrastructure
2. **Extracts outputs** (server IPs, hostnames)
3. **Passes to Ansible** for configuration management

### Example Terraform Outputs
```hcl
output "server_ips" {
  description = "IP addresses of created servers"
  value       = digitalocean_droplet.web[*].ipv4_address
}

output "server_hostnames" {
  description = "Hostnames of created servers"
  value       = digitalocean_droplet.web[*].name
}
```

## Security Features

### Checkov Scanning
- **Purpose**: Detect security misconfigurations
- **Coverage**: Infrastructure as Code security best practices
- **Integration**: Results uploaded to GitHub Security tab

### Environment Protection
- **Staging**: Minimal restrictions for development
- **Production**: Require approvals and restrict to main branch

## Troubleshooting

### Common Issues

**Terraform Cloud Authentication**
```
Error: Required token could not be found
```
- Verify `TF_API_TOKEN` secret is set
- Check token has proper permissions

**Provider Authentication**
```
Error: could not authenticate with DigitalOcean
```
- Verify `DIGITALOCEAN_TOKEN` secret
- Ensure token has required permissions

**State Lock Issues**
```
Error: state is locked
```
- Check Terraform Cloud workspace for active runs
- Cancel stuck operations in Terraform Cloud UI

### Debug Steps
1. **Check workflow logs** in Actions tab
2. **Verify secrets** are properly configured
3. **Test locally** with same configuration
4. **Check Terraform Cloud** workspace status

## Best Practices

### Code Organization
- Keep environments in separate directories
- Use consistent naming conventions
- Document resource purposes

### Security
- Never commit sensitive values
- Use Terraform Cloud for state storage
- Enable security scanning
- Require PR reviews for production

### Workflow Management
- Use descriptive commit messages
- Test in staging before production
- Monitor resource usage and costs
- Implement proper tagging strategies