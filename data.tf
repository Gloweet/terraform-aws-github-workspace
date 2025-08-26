data "github_organization_teams" "all" {}

data "github_repository" "repository" {
  full_name = "${var.repo.repo_org}/${var.repo.name}"
}
