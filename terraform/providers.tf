terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.61.1"
    }
    proxmox-telmate = {
      source  = "telmate/proxmox"
      version = "~> 2.9.14"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.8.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.31.0"
    }

    restapi = {
      source  = "Mastercard/restapi"
      version = "1.19.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
    }

  }
}

provider "restapi" {
  uri                  = var.proxmox.endpoint
  insecure             = var.proxmox.insecure
  write_returns_object = true

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "PVEAPIToken=${var.proxmox.api_token}"
  }
}

provider "kubernetes" {
  host = module.talos.kube_config.kubernetes_client_configuration.host
  client_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_certificate)
  client_key = base64decode(module.talos.kube_config.kubernetes_client_configuration.client_key)
  cluster_ca_certificate = base64decode(module.talos.kube_config.kubernetes_client_configuration.ca_certificate)
}

# BPG Proxmox provider (for VMs and modern resources)
provider "proxmox" {
  endpoint = var.proxmox_api_url
  insecure = true
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  ssh {
    username = "root"
    private_key = file(var.ssh_private_key)
  }
}

# Telmate Proxmox provider (for LXC containers)
provider "proxmox-telmate" {
  pm_api_url          = var.proxmox_api_url
  pm_tls_insecure     = true
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
}
