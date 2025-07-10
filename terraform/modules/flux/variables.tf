variable "github_token" {
  description = "GitHub Personal Access Token for repository access"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub repository owner (username or organization)"
  type        = string
}

variable "github_repository" {
  description = "GitHub repository name for Flux GitOps"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
}

variable "target_path" {
  description = "Path within the Git repository where Flux will store manifests"
  type        = string
  default     = "clusters"
}

variable "branch" {
  description = "Git branch to use for Flux"
  type        = string
  default     = "main"
}



variable "flux_version" {
  description = "Version of Flux to install"
  type        = string
}

variable "network_policy" {
  description = "Enable network policy for Flux"
  type        = bool
  default     = true
}

variable "embedded_manifests" {
  description = "Enable embedded manifests in Flux bootstrap"
  type        = bool
  default     = true
}

variable "components_extra" {
  description = "Extra Flux components to install"
  type        = list(string)
  default     = []
} 