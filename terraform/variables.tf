variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = false
}

variable "machines" {
  description = "List of Proxmox hosts to configure with Tailscale"
  type = list(object({
    name     = string
    ip       = string
    username = string
  }))
}

variable "ssh_private_key" {
  description = "Path to SSH private key file (recommended)"
  type        = string
  default     = ""
}

variable "ssh_password" {
  description = "SSH password (use only if no SSH key available)"
  type        = string
  default     = ""
  sensitive   = false
}

# Proxmox API Configuration (for LXC containers)
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token" {
  description = "Proxmox API Token"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}
variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
}

variable "proxmox_tls_insecure" {
  description = "Whether to skip TLS verification"
  type        = bool
  default     = true
}

# Pi-hole Configuration
variable "pihole_config" {
  description = "Pi-hole LXC container configuration"
  type = object({
    enabled      = bool
    target_node  = string
    vmid         = number
    hostname     = string
    memory       = number
    cores        = number
    disk_size    = string
    ip_address   = string
    gateway      = string
    password     = string
  })
  default = {
    enabled      = false
    target_node  = ""
    vmid         = 200
    hostname     = "pihole"
    memory       = 1024
    cores        = 2
    disk_size    = "8G"
    ip_address   = ""
    gateway      = ""
    password     = ""
  }
}

variable "pihole_admin_password" {
  description = "Pi-hole admin interface password"
  type        = string
  sensitive   = false
}

variable "pihole_admin_password_hash" {
  description = "Pre-hashed Pi-hole admin password (optional)"
  type        = string
  default     = ""
  sensitive   = false
}

variable "custom_dns_records" {
  description = "Custom DNS records for local domain resolution"
  type = list(object({
    hostname = string
    ip       = string
  }))
  default = []
}
 