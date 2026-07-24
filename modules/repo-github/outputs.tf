output "github_repo" {
  description = "All attributes of the GitHub repository"
  value       = var.create_repo ? github_repository.repo[0] : data.github_repository.existing[0]
}

output "ssh_clone_url" {
  description = "URL that can be provided to git clone to clone the repository via SSH"
  value       = var.create_repo ? github_repository.repo[0].ssh_clone_url : data.github_repository.existing[0].ssh_clone_url
}

output "node_id" {
  description = "Node ID of the repository, used for GraphQL API access"
  value       = var.create_repo ? github_repository.repo[0].node_id : data.github_repository.existing[0].node_id
}

output "full_name" {
  description = "Full name of the repository in org/repo format"
  value       = var.create_repo ? github_repository.repo[0].full_name : data.github_repository.existing[0].full_name
}

output "repo_id" {
  description = "Repository ID"
  value       = var.create_repo ? github_repository.repo[0].repo_id : data.github_repository.existing[0].repo_id
}

output "html_url" {
  description = "URL to the repository on GitHub"
  value       = var.create_repo ? github_repository.repo[0].html_url : data.github_repository.existing[0].html_url
}

output "http_clone_url" {
  description = "URL that can be provided to git clone to clone the repository via HTTPS"
  value       = var.create_repo ? github_repository.repo[0].http_clone_url : data.github_repository.existing[0].http_clone_url
}

output "git_clone_url" {
  description = "URL that can be provided to git clone to clone the repository anonymously via the git protocol"
  value       = var.create_repo ? github_repository.repo[0].git_clone_url : data.github_repository.existing[0].git_clone_url
}

output "visibility" {
  description = "Whether the repository is private or public"
  value       = var.create_repo ? github_repository.repo[0].visibility : data.github_repository.existing[0].visibility
}

output "default_branch" {
  description = "Default branch of the repository"
  value = var.create_repo ? var.github_default_branch : (
    length(data.github_repository.existing) > 0 ? lookup(data.github_repository.existing[0], "default_branch", "main") : "main"
  )
}

# resource "github_branch_default" "default_main_branch" {
#   count      = var.github_default_branch != "main" ? 1 : 0 

output "topics" {
  description = "List of topics applied to the repository"
  value       = var.create_repo ? github_repository.repo[0].topics : data.github_repository.existing[0].topics
}

output "template" {
  description = "Template repository this repository was created from"
  value       = var.create_repo ? lookup(github_repository.repo[0], "template", null) : lookup(data.github_repository.existing[0], "template", null)
}
