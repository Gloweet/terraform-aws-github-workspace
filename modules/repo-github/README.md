# Terraform GitHub Repository Module

A comprehensive Terraform module for managing GitHub repositories with advanced features like branch protection, file management, team access control, and deployment keys. You can use this module to create new repositories or manage existing ones.

## Features
- Create new repositories or manage existing ones
- Complete GitHub repository management
- Branch protection rules
- File content management
- Team access configuration
- Action secrets management
- Repository collaborator management
- Deploy key management
- Automated README generation
- Issue management

## Usage

### Creating a New Repository
```hcl
module "new_repository" {
  source = "HappyPathway/repo/github"
  
  name                     = "my-repository"
  repo_org                = "MyOrganization"
  create_repo             = true  # Default, can be omitted
  force_name              = true
  github_repo_description = "Repository description"
  github_repo_topics      = ["terraform", "automation"]
  github_is_private       = false
}
```

### Managing an Existing Repository
```hcl
module "existing_repository" {
  source = "HappyPathway/repo/github"
  
  name        = "existing-repository"
  repo_org    = "MyOrganization"
  create_repo = false  # Tell Terraform to manage existing repository
  
  # All other settings will be applied to the existing repository
  github_repo_topics = ["managed", "terraform"]
  github_has_issues = true
}
```

### Basic Repository

```hcl
module "basic_repo" {
  source = "HappyPathway/repo/github"
  
  name     = "my-project"
  repo_org = "MyOrganization"
}
```

### Repository with Protected Branches

```hcl
module "protected_repo" {
  source = "HappyPathway/repo/github"
  
  name     = "protected-project"
  repo_org = "MyOrganization"
  
  branch_protections = {
    main = {
      required_status_checks = true
      enforce_admins        = true
      required_reviews      = 2
    }
  }
}
```

### Repository with Managed Files

```hcl
module "managed_repo" {
  source = "HappyPathway/repo/github"
  
  name     = "managed-project"
  repo_org = "MyOrganization"
  
  managed_extra_files = {
    "README.md" = {
      content   = file("${path.module}/templates/readme.md")
      overwrite = true
    }
    "CONTRIBUTING.md" = {
      content   = file("${path.module}/templates/contributing.md")
      overwrite = false
    }
  }
}
```

### Repository with Deploy Keys

```hcl
module "repo_with_deploy_keys" {
  source = "HappyPathway/repo/github"
  
  name     = "my-project-with-deploy-keys"
  repo_org = "MyOrganization"
  
  deploy_keys = [
    {
      title     = "CI Server Key"
      key       = "ssh-rsa AAAAB3NzaC1yc2EAAA..."
      read_only = true  # Default is true, can be omitted
    },
    {
      title     = "Deploy Server Key"
      key       = "ssh-rsa AAAAB3NzaC1yc2EBBB..."
      read_only = false  # Write access for deployment
    }
  ]
}
```

## Inputs

| Name | Description | Type | Required | Default |
|------|-------------|------|----------|---------|
| name | Repository name | string | Yes | - |
| repo_org | GitHub organization name | string | No | null |
| create_repo | Whether to create a new repository or manage existing | bool | No | true |
| force_name | Keep exact repository name (no date suffix) | bool | No | false |
| github_repo_description | Repository description | string | No | null |
| github_repo_topics | Repository topics | list(string) | No | [] |
| github_is_private | Make repository private | bool | No | true |
| // ...other inputs... |

## Outputs

| Name | Description |
|------|-------------|
| github_repo | All repository attributes (see details below) |
| ssh_clone_url | SSH clone URL |
| node_id | Repository node ID for GraphQL |
| full_name | Full repository name (org/repo) |
| repo_id | Repository ID |
| html_url | Repository web URL |
| http_clone_url | HTTPS clone URL |
| git_clone_url | Git protocol clone URL |
| visibility | Repository visibility (public/private) |
| default_branch | Default branch name |
| topics | Repository topics |
| template | Template repository info |

### Complete Repository Attributes

The `github_repo` output includes:

Basic Info:
- `name` - Repository name
- `full_name` - Full repository name (org/repo)
- `description` - Repository description
- `html_url` - GitHub web URL
- `ssh_clone_url` - SSH clone URL
- `http_clone_url` - HTTPS clone URL
- `git_clone_url` - Git protocol URL
- `visibility` - Public or private status

Settings:
- `topics` - Repository topics
- `has_issues` - Issue tracking enabled
- `has_projects` - Project boards enabled
- `has_wiki` - Wiki enabled
- `is_template` - Template repository status
- `allow_merge_commit` - Merge commit allowed
- `allow_squash_merge` - Squash merge allowed
- `allow_rebase_merge` - Rebase merge allowed
- `allow_auto_merge` - Auto-merge enabled
- `delete_branch_on_merge` - Branch deletion on merge

Additional Info:
- `default_branch` - Default branch name
- `archived` - Archive status
- `homepage_url` - Homepage URL if set
- `vulnerability_alerts` - Vulnerability alerts status
- `template` - Template repository details if used
- `gitignore_template` - .gitignore template if used
- `license_template` - License template if used

## Limitations and Important Notes

### Managing Existing Repositories
When managing existing repositories (`create_repo = false`):
- The repository must already exist in the specified organization
- You must have admin access to the repository
- Some settings may be read-only if they were set during repository creation
- Initial repository settings (like `auto_init`) are ignored
- Branch protection rules can only be added, not removed

### Error Cases
The module will fail if:
- When `create_repo = false` and the repository doesn't exist
- When `create_repo = false` and `repo_org` is not specified
- When trying to manage a repository you don't have admin access to
- When applying branch protection rules to a private repository without a GitHub Enterprise plan

### Best Practices
1. When managing existing repositories:
   - Start with `create_repo = false` and minimal settings
   - Gradually add configuration to avoid conflicts
   - Use `terraform plan` to verify changes
   - Consider using `lifecycle` blocks to ignore specific attributes

2. For new repositories:
   - Use `create_repo = true` (default)
   - Set `force_name = true` to maintain consistent naming
   - Configure all settings during initial creation

## Testing

This module includes automated tests that verify:
- Repository creation
- Data source lookups for existing repositories
- All output attributes

Run the tests using:
```bash
terraform test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see [LICENSE](LICENSE) for details


[![Terraform Validation](https://github.com/HappyPathway/terraform-github-repo/actions/workflows/terraform.yaml/badge.svg)](https://github.com/HappyPathway/terraform-github-repo/actions/workflows/terraform.yaml)


[![Modtest Dev](https://github.com/HappyPathway/terraform-github-repo/actions/workflows/modtest-dev.yaml/badge.svg)](https://github.com/HappyPathway/terraform-github-repo/actions/workflows/modtest-dev.yaml)

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | 6.6.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.0.6 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_secret.environment_secrets](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_secret) | resource |
| [github_actions_environment_variable.environment_variables](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_secret.secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [github_actions_variable.variable](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_variable) | resource |
| [github_branch.branch](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch) | resource |
| [github_branch_default.default_main_branch](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_default) | resource |
| [github_branch_protection.protection](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/branch_protection) | resource |
| [github_repository.repo](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository) | resource |
| [github_repository_collaborator.collaborators](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_collaborator) | resource |
| [github_repository_deploy_key.deploy_key](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_deploy_key) | resource |
| [github_repository_environment.environments](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_environment) | resource |
| [github_repository_file.codeowners](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |
| [github_repository_file.extra_files](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |
| [github_repository_file.managed_extra_files](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/repository_file) | resource |
| [github_team_repository.admin](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/team_repository) | resource |
| [tls_private_key.deploy_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [github_organization_teams.root_teams](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/organization_teams) | data source |
| [github_ref.ref](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/ref) | data source |
| [github_repository.existing](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [github_repository.template_repo](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/repository) | data source |
| [github_team.admin_teams](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team) | data source |
| [github_team.environment_teams](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/team) | data source |
| [github_user.collaborators](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user) | data source |
| [github_user.environment_users](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user) | data source |
| [github_user.pull_request_bypassers](https://registry.terraform.io/providers/integrations/github/latest/docs/data-sources/user) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_codeowners"></a> [additional\_codeowners](#input\_additional\_codeowners) | Additional entries for CODEOWNERS file | `list(string)` | `[]` | no |
| <a name="input_admin_teams"></a> [admin\_teams](#input\_admin\_teams) | Teams to grant admin access | `list(string)` | `[]` | no |
| <a name="input_allow_unsigned_files"></a> [allow\_unsigned\_files](#input\_allow\_unsigned\_files) | Whether to allow file management even when signed commits are required | `bool` | `false` | no |
| <a name="input_archive_on_destroy"></a> [archive\_on\_destroy](#input\_archive\_on\_destroy) | Archive repository instead of deleting on destroy | `bool` | `true` | no |
| <a name="input_archived"></a> [archived](#input\_archived) | Archive this repository | `bool` | `false` | no |
| <a name="input_collaborators"></a> [collaborators](#input\_collaborators) | Map of collaborators and their permission levels | `map(string)` | `{}` | no |
| <a name="input_commit_author"></a> [commit\_author](#input\_commit\_author) | The author name to use for file commits | `string` | `"Terraform"` | no |
| <a name="input_commit_email"></a> [commit\_email](#input\_commit\_email) | The email to use for file commits | `string` | `"terraform@roknsound.com"` | no |
| <a name="input_create_codeowners"></a> [create\_codeowners](#input\_create\_codeowners) | Create CODEOWNERS file | `bool` | `true` | no |
| <a name="input_create_repo"></a> [create\_repo](#input\_create\_repo) | Whether to create a new repository or manage an existing one | `bool` | `true` | no |
| <a name="input_deploy_keys"></a> [deploy\_keys](#input\_deploy\_keys) | List of SSH deploy keys to add to the repository | <pre>list(object({<br>    title = string<br>    key   = optional(string, "")<br>    # The key is optional because it can be generated<br>    # by the module itself if create is set to true<br>    # and the key is not provided<br>    read_only = optional(bool, true)<br>    create    = optional(bool, false)<br>  }))</pre> | `[]` | no |
| <a name="input_enforce_prs"></a> [enforce\_prs](#input\_enforce\_prs) | Enforce pull request reviews | `bool` | `true` | no |
| <a name="input_environments"></a> [environments](#input\_environments) | List of GitHub environments to create for the repository | <pre>list(object({<br>    name = string<br>    reviewers = optional(object({<br>      teams = optional(list(string), [])<br>      users = optional(list(string), [])<br>    }), {})<br>    deployment_branch_policy = optional(object({<br>      protected_branches     = optional(bool, true)<br>      custom_branch_policies = optional(bool, false)<br>    }), {})<br>    secrets = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>    vars = optional(list(object({<br>      name  = string<br>      value = string<br>    })), [])<br>  }))</pre> | `[]` | no |
| <a name="input_extra_files"></a> [extra\_files](#input\_extra\_files) | Additional files to create in the repository | <pre>list(object({<br>    path    = string<br>    content = string<br>  }))</pre> | `[]` | no |
| <a name="input_force_name"></a> [force\_name](#input\_force\_name) | Keep exact repository name (no date suffix) | `bool` | `false` | no |
| <a name="input_github_allow_auto_merge"></a> [github\_allow\_auto\_merge](#input\_github\_allow\_auto\_merge) | Allow pull requests to be automatically merged | `bool` | `false` | no |
| <a name="input_github_allow_merge_commit"></a> [github\_allow\_merge\_commit](#input\_github\_allow\_merge\_commit) | Allow merge commits | `bool` | `false` | no |
| <a name="input_github_allow_rebase_merge"></a> [github\_allow\_rebase\_merge](#input\_github\_allow\_rebase\_merge) | Allow rebase merging | `bool` | `false` | no |
| <a name="input_github_allow_squash_merge"></a> [github\_allow\_squash\_merge](#input\_github\_allow\_squash\_merge) | Allow squash merging | `bool` | `true` | no |
| <a name="input_github_allow_update_branch"></a> [github\_allow\_update\_branch](#input\_github\_allow\_update\_branch) | Allow updating pull request branches | `bool` | `true` | no |
| <a name="input_github_auto_init"></a> [github\_auto\_init](#input\_github\_auto\_init) | Initialize repository with README | `bool` | `true` | no |
| <a name="input_github_codeowners_team"></a> [github\_codeowners\_team](#input\_github\_codeowners\_team) | n/a | `string` | `"terraform-reviewers"` | no |
| <a name="input_github_default_branch"></a> [github\_default\_branch](#input\_github\_default\_branch) | Default branch name | `string` | `"main"` | no |
| <a name="input_github_delete_branch_on_merge"></a> [github\_delete\_branch\_on\_merge](#input\_github\_delete\_branch\_on\_merge) | Delete head branch after merge | `bool` | `true` | no |
| <a name="input_github_dismiss_stale_reviews"></a> [github\_dismiss\_stale\_reviews](#input\_github\_dismiss\_stale\_reviews) | Dismiss stale pull request approvals | `bool` | `true` | no |
| <a name="input_github_enforce_admins_branch_protection"></a> [github\_enforce\_admins\_branch\_protection](#input\_github\_enforce\_admins\_branch\_protection) | Enforce branch protection rules on administrators | `bool` | `true` | no |
| <a name="input_github_has_discussions"></a> [github\_has\_discussions](#input\_github\_has\_discussions) | Enable discussions feature | `bool` | `false` | no |
| <a name="input_github_has_downloads"></a> [github\_has\_downloads](#input\_github\_has\_downloads) | Enable downloads feature | `bool` | `false` | no |
| <a name="input_github_has_issues"></a> [github\_has\_issues](#input\_github\_has\_issues) | Enable issues feature | `bool` | `false` | no |
| <a name="input_github_has_projects"></a> [github\_has\_projects](#input\_github\_has\_projects) | Enable projects feature | `bool` | `true` | no |
| <a name="input_github_has_wiki"></a> [github\_has\_wiki](#input\_github\_has\_wiki) | Enable wiki feature | `bool` | `true` | no |
| <a name="input_github_is_private"></a> [github\_is\_private](#input\_github\_is\_private) | Make repository private | `bool` | `true` | no |
| <a name="input_github_merge_commit_message"></a> [github\_merge\_commit\_message](#input\_github\_merge\_commit\_message) | Message for merge commits | `string` | `"PR_TITLE"` | no |
| <a name="input_github_merge_commit_title"></a> [github\_merge\_commit\_title](#input\_github\_merge\_commit\_title) | Title for merge commits | `string` | `"MERGE_MESSAGE"` | no |
| <a name="input_github_org_teams"></a> [github\_org\_teams](#input\_github\_org\_teams) | Organization teams configuration | `list(any)` | `null` | no |
| <a name="input_github_pro_enabled"></a> [github\_pro\_enabled](#input\_github\_pro\_enabled) | Is this a Github Pro Account? If not, then it's limited in feature set | `bool` | `false` | no |
| <a name="input_github_push_restrictions"></a> [github\_push\_restrictions](#input\_github\_push\_restrictions) | List of team/user IDs with push access | `list(string)` | `[]` | no |
| <a name="input_github_repo_description"></a> [github\_repo\_description](#input\_github\_repo\_description) | Repository description | `string` | `null` | no |
| <a name="input_github_repo_topics"></a> [github\_repo\_topics](#input\_github\_repo\_topics) | Repository topics | `list(string)` | `[]` | no |
| <a name="input_github_require_code_owner_reviews"></a> [github\_require\_code\_owner\_reviews](#input\_github\_require\_code\_owner\_reviews) | Require code owner review | `bool` | `true` | no |
| <a name="input_github_required_approving_review_count"></a> [github\_required\_approving\_review\_count](#input\_github\_required\_approving\_review\_count) | Number of approvals needed for pull requests | `number` | `1` | no |
| <a name="input_github_squash_merge_commit_message"></a> [github\_squash\_merge\_commit\_message](#input\_github\_squash\_merge\_commit\_message) | Message for squash merge commits | `string` | `"COMMIT_MESSAGES"` | no |
| <a name="input_github_squash_merge_commit_title"></a> [github\_squash\_merge\_commit\_title](#input\_github\_squash\_merge\_commit\_title) | Title for squash merge commits | `string` | `"COMMIT_OR_PR_TITLE"` | no |
| <a name="input_gitignore_template"></a> [gitignore\_template](#input\_gitignore\_template) | Gitignore template to use | `string` | `null` | no |
| <a name="input_homepage_url"></a> [homepage\_url](#input\_homepage\_url) | Repository homepage URL | `string` | `null` | no |
| <a name="input_is_template"></a> [is\_template](#input\_is\_template) | Make this repository a template | `bool` | `false` | no |
| <a name="input_license_template"></a> [license\_template](#input\_license\_template) | License template to use for the repository | `string` | `null` | no |
| <a name="input_managed_extra_files"></a> [managed\_extra\_files](#input\_managed\_extra\_files) | Additional files to manage in the repository | <pre>list(object({<br>    path    = string<br>    content = string<br>  }))</pre> | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the repository | `string` | n/a | yes |
| <a name="input_pages_config"></a> [pages\_config](#input\_pages\_config) | Configuration for GitHub Pages | <pre>object({<br>    branch = optional(string, "gh-pages")<br>    path   = optional(string, "/")<br>    cname  = optional(string)<br>  })</pre> | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix to add to repository name | `string` | `null` | no |
| <a name="input_pull_request_bypassers"></a> [pull\_request\_bypassers](#input\_pull\_request\_bypassers) | Users/teams that can bypass pull request requirements | `list(string)` | `[]` | no |
| <a name="input_repo_org"></a> [repo\_org](#input\_repo\_org) | GitHub organization name | `string` | `null` | no |
| <a name="input_require_last_push_approval"></a> [require\_last\_push\_approval](#input\_require\_last\_push\_approval) | Require approval from the last pusher | `bool` | `false` | no |
| <a name="input_require_signed_commits"></a> [require\_signed\_commits](#input\_require\_signed\_commits) | Whether to require signed commits for the default branch | `bool` | `false` | no |
| <a name="input_required_status_checks"></a> [required\_status\_checks](#input\_required\_status\_checks) | Required status checks for protected branches | <pre>object({<br>    contexts = list(string)<br>    strict   = optional(bool, false)<br>  })</pre> | `null` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | GitHub Actions secrets | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_security_and_analysis"></a> [security\_and\_analysis](#input\_security\_and\_analysis) | Security and analysis settings for the repository | <pre>object({<br>    advanced_security = optional(object({<br>      status = string<br>    }), { status = "disabled" })<br>    secret_scanning = optional(object({<br>      status = string<br>    }), { status = "disabled" })<br>    secret_scanning_push_protection = optional(object({<br>      status = string<br>    }), { status = "disabled" })<br>  })</pre> | `null` | no |
| <a name="input_template_repo"></a> [template\_repo](#input\_template\_repo) | Template repository name | `string` | `null` | no |
| <a name="input_template_repo_org"></a> [template\_repo\_org](#input\_template\_repo\_org) | Template repository organization | `string` | `null` | no |
| <a name="input_vars"></a> [vars](#input\_vars) | GitHub Actions variables | <pre>list(object({<br>    name  = string<br>    value = string<br>  }))</pre> | `[]` | no |
| <a name="input_vulnerability_alerts"></a> [vulnerability\_alerts](#input\_vulnerability\_alerts) | Enable Dependabot alerts | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_default_branch"></a> [default\_branch](#output\_default\_branch) | Default branch of the repository |
| <a name="output_full_name"></a> [full\_name](#output\_full\_name) | Full name of the repository in org/repo format |
| <a name="output_git_clone_url"></a> [git\_clone\_url](#output\_git\_clone\_url) | URL that can be provided to git clone to clone the repository anonymously via the git protocol |
| <a name="output_github_repo"></a> [github\_repo](#output\_github\_repo) | All attributes of the GitHub repository |
| <a name="output_html_url"></a> [html\_url](#output\_html\_url) | URL to the repository on GitHub |
| <a name="output_http_clone_url"></a> [http\_clone\_url](#output\_http\_clone\_url) | URL that can be provided to git clone to clone the repository via HTTPS |
| <a name="output_node_id"></a> [node\_id](#output\_node\_id) | Node ID of the repository, used for GraphQL API access |
| <a name="output_repo_id"></a> [repo\_id](#output\_repo\_id) | Repository ID |
| <a name="output_ssh_clone_url"></a> [ssh\_clone\_url](#output\_ssh\_clone\_url) | URL that can be provided to git clone to clone the repository via SSH |
| <a name="output_template"></a> [template](#output\_template) | Template repository this repository was created from |
| <a name="output_topics"></a> [topics](#output\_topics) | List of topics applied to the repository |
| <a name="output_visibility"></a> [visibility](#output\_visibility) | Whether the repository is private or public |
<!-- END_TF_DOCS -->
