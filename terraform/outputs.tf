output "installation_status" {
  description = "Tailscale installation status for each Proxmox host"
  value       = module.tailscale.installation_status
}

output "hosts_configured" {
  description = "Proxmox hosts configured with Tailscale"
  value       = module.tailscale.hosts_configured
}

# Pi-hole outputs
output "pihole_status" {
  description = "Pi-hole deployment status"
  value       = module.pihole.pihole_status
}

output "pihole_web_interface" {
  description = "Pi-hole web interface URL"
  value       = module.pihole.pihole_web_interface
}

output "pihole_ip_address" {
  description = "Pi-hole IP address"
  value       = module.pihole.pihole_ip_address
}

output "custom_dns_records" {
  description = "Custom DNS records configured in Pi-hole"
  value       = module.pihole.custom_dns_records
}

output "kube_config" {
  description = "Kubeconfig for the cluster"
  value       = module.talos.kube_config
  sensitive   = true
}