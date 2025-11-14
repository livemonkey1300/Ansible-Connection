variable "server_tag" {
    description = "Tag to identify the staging server"
    type        = string
    default     = "staging"
}

variable "digital_region" {
    description = "DigitalOcean region for the staging server"
    type        = string
    default     = "nyc1"
  
}