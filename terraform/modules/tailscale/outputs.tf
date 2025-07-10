output "installation_status" {
  description = "Tailscale installation status for each Proxmox host"
  value = {
    for machine in var.machines : machine.name => {
      ip        = machine.ip
      username  = machine.username
      installed = "completed"
    }
  }
  depends_on = [null_resource.tailscale_install]
}

output "hosts_configured" {
  description = "Proxmox hosts configured with Tailscale"
  value = {
    for machine in var.machines : machine.name => {
      ip       = machine.ip
      username = machine.username
    }
  }
} 