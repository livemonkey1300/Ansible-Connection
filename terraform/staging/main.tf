terraform { 
  cloud { 
    
    organization = "gcp-live" 

    workspaces { 
      name = "ansible-connection-staging" 
    } 
  } 
required_providers {
    digitalocean = {
        source = "digitalocean/digitalocean"
        version = "~> 2.0"
    }
    vault = {
      source = "hashicorp/vault"
      version = "5.4.0"
    }
}
}

provider "vault" {}

resource "vault_mount" "kv" {
    path        = "secret"
    type        = "kv"
    options     = { version = "2" }
    description = "KV Version 2 secret engine mount"
}

# Enable SSH secrets engine
resource "vault_mount" "ssh" {
    path        = "ssh"
    type        = "ssh"
    description = "SSH secrets engine"
}

# Configure SSH secrets engine for key generation
resource "vault_ssh_secret_backend_role" "ssh_key_role" {
    backend    = vault_mount.ssh.path
    name       = "ssh-key-role"
    key_type   = "ca"
    allow_user_certificates = true
    allowed_users = "*"
    default_user = "root"
    ttl = "30m"
    max_ttl = "1h"
}

# Generate SSH key pair
resource "vault_generic_secret" "ssh_keypair" {
    path = "${vault_mount.kv.path}/ssh-keys"
    
    data_json = jsonencode({
        public_key  = vault_ssh_secret_backend_role.ssh_key_role.public_key
        private_key = vault_ssh_secret_backend_role.ssh_key_role.private_key
    })
}

# Create DigitalOcean SSH key using the generated public key
resource "digitalocean_ssh_key" "vault_generated" {
    name       = "vault-generated-key"
    public_key = jsondecode(vault_generic_secret.ssh_keypair.data_json)["public_key"]
}

# Create GitHub Actions service account policy
resource "vault_policy" "github_actions_policy" {
    name = "github-actions-ssh-policy"
    
    policy = <<EOT
path "secret/data/ssh-keys" {
  capabilities = ["read"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOT
}

# Create AppRole for GitHub Actions
resource "vault_auth_backend" "approle" {
    type = "approle"
    path = "approle"
}

resource "vault_approle_auth_backend_role" "github_actions" {
    backend        = vault_auth_backend.approle.path
    role_name      = "github-actions"
    token_policies = [vault_policy.github_actions_policy.name]
    token_ttl      = 600
    token_max_ttl  = 1200
}

# Output the SSH key ID for use with droplets
output "ssh_key_id" {
    value = digitalocean_ssh_key.vault_generated.id
}

# Output AppRole credentials for GitHub Actions
output "github_actions_role_id" {
    value = vault_approle_auth_backend_role.github_actions.role_id
    description = "Role ID for GitHub Actions authentication"
}

output "github_actions_secret_id" {
    value = vault_approle_auth_backend_role.github_actions.secret_id
    sensitive = true
    description = "Secret ID for GitHub Actions authentication"
}

output "vault_ssh_key_path" {
    value = "secret/data/ssh-keys"
    description = "Path to retrieve SSH keys from Vault"
}