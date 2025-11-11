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

provider "vault" {

}

resource "vault_mount" "kv" {
    path        = "secret"
    type        = "kv"
    options     = { version = "2" }
    description = "KV Version 2 secret engine mount"
}