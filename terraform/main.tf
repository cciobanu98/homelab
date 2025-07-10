# Tailscale module for all configured Proxmox hosts
module "tailscale" {
  source = "./modules/tailscale"
  
  tailscale_auth_key = var.tailscale_auth_key
  machines          = var.machines
  ssh_private_key   = var.ssh_private_key
  ssh_password      = var.ssh_password
}

# Pi-hole module for DNS filtering
module "pihole" {
  source = "./modules/pihole"
  
  pihole_config              = var.pihole_config
  tailscale_auth_key         = var.tailscale_auth_key
  ssh_private_key            = var.ssh_private_key
  ssh_password               = var.ssh_password
  pihole_admin_password      = var.pihole_admin_password
  pihole_admin_password_hash = var.pihole_admin_password_hash
  custom_dns_records         = var.custom_dns_records
}

module "talos" {
  source = "./modules/talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version = "v1.10.4"
    schematic = file("./modules/talos/image/schematic.yaml")
  }

  cilium = {
    install = file("./modules/talos/inline-manifests/cilium-install.yaml")
    values = file("./../kubernetes/cilium/values.yaml")
  }

  cluster = {
    name            = "talos"
    endpoint        = "192.168.100.100"
    gateway         = "192.168.100.1"
    talos_version   = "v1.10.4"
    proxmox_cluster = "homelab"
  }

  nodes = {
    "ctrl-00" = {
      host_node     = "server1"
      machine_type  = "controlplane"
      ip            = "192.168.100.100"
      mac_address   = "BC:24:11:2E:C8:00"
      vm_id         = 100
      cpu           = 3
      ram_dedicated = 8192
    }
    "ctrl-01" = {
      host_node     = "server2"
      machine_type  = "controlplane"
      ip            = "192.168.100.101"
      mac_address   = "BC:24:11:2E:C8:01"
      vm_id         = 101
      cpu           = 3
      ram_dedicated = 8192
      igpu          = false
    }
    "work-00" = {
      host_node     = "server1"
      machine_type  = "worker"
      ip            = "192.168.100.110"
      mac_address   = "BC:24:11:2E:08:00"
      vm_id         = 110
      cpu           = 2
      ram_dedicated = 4096
      igpu          = false
    }
    "work-01" = {
      host_node     = "server2"
      machine_type  = "worker"
      ip            = "192.168.100.111"
      mac_address   = "BC:24:11:2E:08:01"
      vm_id         = 111
      cpu           = 3
      ram_dedicated = 8192
      igpu          = false
    }
  }
}