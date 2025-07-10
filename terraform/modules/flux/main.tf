terraform {
  required_providers {
    flux = {
      source = "fluxcd/flux"
    }
    github = {
      source = "integrations/github"
    }
  }
}

# Data source for existing repository
data "github_repository" "this" {
  full_name = "${var.github_owner}/${var.github_repository}"
}

# Bootstrap Flux
resource "flux_bootstrap_git" "this" {
  depends_on = [data.github_repository.this]

  path               = "${var.target_path}/${var.cluster_name}"
  embedded_manifests = var.embedded_manifests
  version            = var.flux_version
  network_policy     = var.network_policy
  components_extra   = var.components_extra
} 