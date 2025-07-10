# Tailscale module for all configured Proxmox hosts
module "tailscale" {
  source = "./modules/tailscale"

  tailscale_auth_key = var.tailscale_auth_key
  ssh_private_key = var.ssh_private_key
  machines = [
    {
      name     = "server1"
      ip       = "192.168.100.10"
      username = "root"
    },
    {
      name     = "server2"
      ip       = "192.168.100.20"
      username = "root"
    }
  ]
}

# Pi-hole module for DNS filtering
module "pihole" {
  source = "./modules/pihole"

  pihole_config = {
    enabled     = true
    target_node = "server1"
    vmid        = 200
    hostname    = "pihole"
    memory      = 1024
    cores       = 2
    disk_size   = "8G"
    ip_address  = "192.168.100.200"
    gateway     = "192.168.100.1"
    password    = var.pihole_password
  }
  tailscale_auth_key         = var.tailscale_auth_key
  ssh_private_key            = var.ssh_private_key
  pihole_admin_password      = var.pihole_admin_password
  custom_dns_records = [
    {
      hostname = "server1.lab"
      ip       = "192.168.100.10"
    },
    {
      hostname = "server2.lab"
      ip       = "192.168.100.20"
    },
    {
      hostname = "pihole.lab"
      ip       = "192.168.100.200"
    },
    {
      hostname = "k8s.lab"
      ip       = "192.168.100.100"
    },
    {
      hostname = "apps.lab"
      ip       = "192.168.100.223"
    }
  ]
}

module "talos" {
  source = "./modules/talos"

  providers = {
    proxmox = proxmox
  }

  image = {
    version   = "v1.10.4"
    schematic = file("./modules/talos/image/schematic.yaml")
  }

  cilium = {
    install = file("./modules/talos/inline-manifests/cilium-install.yaml")
    values  = file("./../kubernetes/cilium/values.yaml")
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

# Flux GitOps module for cluster management
module "flux" {
  source = "./modules/flux"

  providers = {
    flux   = flux
    github = github
  }

  depends_on = [module.talos]

  target_path = "flux/clusters"
  github_token      = var.github_token
  github_owner      = "cciobanu98"
  github_repository = "homelab"
  cluster_name      = "homelab-prod"
  flux_version = "v2.6.0"
  embedded_manifests = true
  network_policy     = true
  components_extra   = [
    "image-reflector-controller",
    "image-automation-controller"
  ]
}