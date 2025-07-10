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

 