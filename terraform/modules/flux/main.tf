terraform {
  required_version = ">= 1.7.0"

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

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
}

# Data source for existing repository
data "github_repository" "this" {
  name = var.github_repository
}

# Bootstrap Flux
resource "flux_bootstrap_git" "this" {
  depends_on = github_repository.this

  repository_url     = "https://github.com/${var.github_owner}/${var.github_repository}"
  branch             = var.branch
  path               = "${var.target_path}/${var.cluster_name}"
  
  embedded_manifests = var.embedded_manifests
  version            = var.flux_version
  network_policy     = var.network_policy
  components_extra   = var.components_extra
} 