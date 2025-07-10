output "pihole_container_id" {
  description = "Pi-hole LXC container ID"
  value       = var.pihole_config.enabled ? proxmox_lxc.pihole[0].id : null
}

output "pihole_ip_address" {
  description = "Pi-hole IP address"
  value       = var.pihole_config.enabled ? var.pihole_config.ip_address : null
}

output "pihole_web_interface" {
  description = "Pi-hole web interface URL"
  value       = var.pihole_config.enabled ? "http://${var.pihole_config.ip_address}/admin" : null
}

output "pihole_hostname" {
  description = "Pi-hole hostname"
  value       = var.pihole_config.enabled ? var.pihole_config.hostname : null
}

output "custom_dns_records" {
  description = "Custom DNS records configured in Pi-hole"
  value       = var.pihole_config.enabled ? var.custom_dns_records : []
}

output "pihole_status" {
  description = "Pi-hole deployment status"
  value = var.pihole_config.enabled ? {
    deployed    = "success"
    vmid        = var.pihole_config.vmid
    target_node = var.pihole_config.target_node
    memory      = var.pihole_config.memory
    cores       = var.pihole_config.cores
    dns_records_count = length(var.custom_dns_records)
  } : null
  depends_on = [null_resource.pihole_setup]
} 