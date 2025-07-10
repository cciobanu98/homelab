variable "proxmox_api_url" {
  description = "Promox api URL"
  type = string
  default = "https://192.168.100.10:8006/api2/json"
}
variable "tailscale_auth_key" {
  description = "Tailscale authentication key"
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  description = "Path to SSH private key file"
  type        = string
  sensitive = true
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive = true
}
variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive = true
}

variable "pihole_admin_password" {
  description = "Pi-hole admin interface password"
  type        = string
  sensitive   = true
}

variable "pihole_password" {
  description = "Pi-hole vm password"
  type        = string
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token for Flux GitOps"
  type        = string
  sensitive   = true
}
 