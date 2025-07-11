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
}

variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = false
}

variable "ssh_private_key" {
  description = "Path to SSH private key file"
  type        = string
  default     = ""
}

variable "ssh_password" {
  description = "SSH password for Proxmox hosts"
  type        = string
  default     = ""
  sensitive   = false
}

variable "ssh_public_key" {
  description = "SSH public key content"
  type        = string
  default     = ""
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

variable "custom_k8s_domain" {
  description = "Custom DNS records for k8s domain: example: .apps.lab"
  type = object({
    hostname = string
    ip       = string
  })
}