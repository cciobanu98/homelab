output "repository_name" {
  description = "Name of the GitHub repository"
  value       = var.github_repository
}

output "repository_url" {
  description = "URL of the GitHub repository"
  value       = data.github_repository.this[0].html_url
}

output "repository_clone_url" {
  description = "Clone URL of the GitHub repository"
  value       = data.github_repository.this[0].clone_url
}

output "repository_ssh_clone_url" {
  description = "SSH clone URL of the GitHub repository"
  value       = data.github_repository.this[0].ssh_clone_url
}

output "flux_path" {
  description = "Path within the repository where Flux manifests are stored"
  value       = "${var.target_path}/${var.cluster_name}"
}

output "flux_branch" {
  description = "Git branch used by Flux"
  value       = var.branch
}

output "cluster_name" {
  description = "Name of the cluster"
  value       = var.cluster_name
} 