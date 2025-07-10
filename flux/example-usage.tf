# Example usage of the Flux module
# This is just for reference - the actual module call is in terraform/main.tf

terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.2"
    }
    github = {
      source  = "integrations/github"
      version = ">= 6.1"
    }
  }
}

# Example: Basic Flux deployment
module "flux_basic" {
  source = "../terraform/modules/flux"

  github_token      = var.github_token
  github_owner      = "your-username"
  github_repository = "homelab-gitops"
  cluster_name      = "homelab"
}

# Example: Advanced Flux deployment with custom settings
module "flux_advanced" {
  source = "../terraform/modules/flux"

  github_token      = var.github_token
  github_owner      = "your-username"
  github_repository = "k8s-gitops"
  cluster_name      = "production"

  # Repository settings
  create_repository     = true
  repository_visibility = "private"
  branch               = "main"

  # Flux configuration
  target_path          = "clusters"
  flux_version         = "v2.2.0"
  network_policy       = true
  embedded_manifests   = true
  components_extra     = [
    "image-reflector-controller",
    "image-automation-controller"
  ]
}

# Variables needed for the examples
variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
} 