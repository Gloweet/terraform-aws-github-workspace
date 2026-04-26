data "github_repository" "repo" {
  count = var.repo.create_repo ? 0 : 1
  name  = var.repo.name
}

module "repo" {
  source                  = "HappyPathway/repo/github"
  count                   = var.repo.create_repo ? 1 : 0
  github_repo_description = var.repo.description
  github_auto_init        = var.repo.auto_init
  repo_org                = var.repo.repo_org
  name                    = var.repo.name
  github_repo_topics      = var.repo.repo_topics
  is_template             = var.repo.is_template
  force_name              = true
  create_codeowners       = var.repo.create_codeowners
  github_codeowners_team  = var.repo.codeowners
  enforce_prs             = var.repo.enforce_prs
  collaborators           = var.repo.collaborators
  github_is_private       = var.repo.is_private
  github_org_teams        = var.repo.github_organization_teams
  archive_on_destroy      = var.repo.archive_on_destroy
  extra_files             = var.repo.extra_files
  managed_extra_files     = var.repo.managed_extra_files
  secrets                 = var.repo.secrets
  vars                    = var.repo.vars
  admin_teams             = var.repo.admin_teams
  pull_request_bypassers  = var.repo.pull_request_bypassers
}

locals {
  repo = var.repo.create_repo ? one(module.repo).github_repo : one(data.github_repository.repo)
}
