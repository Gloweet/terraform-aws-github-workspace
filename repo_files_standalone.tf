# Resource to create a GitHub repository file for Terraform plan workflow
resource "github_repository_file" "standalone_plan" {
  for_each = var.standalone ? {
    for env in var.environments : env.name => env
  } : {}

  repository          = local.repo.name
  file                = ".github/workflows/terraform-plan-${each.value.name}.yml"
  overwrite_on_create = true
  content = templatefile(
    "${path.module}/workflow-templates/standalone/terraform-plan.tftpl",
    {
      repo_name       = local.repo.name,
      repo_org        = var.repo.repo_org,
      reviewers       = each.value.reviewers.teams,
      branch          = compact([each.value.deployment_branch_policy.branch, local.repo.default_branch])[0],
      runs_on         = each.value.runner_group,
      aws_auth        = var.composite_action_repos.aws_auth,
      gh_auth         = var.composite_action_repos.gh_auth,
      setup_terraform = var.composite_action_repos.setup_terraform,
      terraform_init  = var.composite_action_repos.terraform_init,
      terraform_plan  = var.composite_action_repos.terraform_plan,
      terraform_apply = var.composite_action_repos.terraform_apply,
      checkout        = var.composite_action_repos.checkout,
      environment     = lookup(github_repository_environment.this, each.value.name).environment
      backend_config  = each.value.state_config.set_backend ? "backend-configs/${each.key}.tf" : "backend.tf"
      cache_bucket    = each.value.cache_bucket
      s3_cleanup      = var.composite_action_repos.s3_cleanup
      working_dir     = var.repo.working_dir
      vars = distinct(concat(
        [for var in var.repo.vars : var.name],
        [for var in each.value.vars : var.name]
      ))
      secrets = distinct(concat(
        [for secret in var.repo.secrets : secret.name],
        [for secret in each.value.secrets : secret.name]
      ))
    }
  )
  branch = local.repo.default_branch
  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}

# Resource to create a GitHub repository file for Terraform apply workflow
resource "github_repository_file" "standalone_apply" {
  for_each = var.standalone ? {
    for env in var.environments : env.name => env
  } : {}

  repository          = local.repo.name
  file                = ".github/workflows/terraform-apply-${each.value.name}.yml"
  overwrite_on_create = true
  content = templatefile(
    "${path.module}/workflow-templates/standalone/terraform-apply.tftpl",
    {
      repo_name       = local.repo.name,
      repo_org        = var.repo.repo_org,
      reviewers       = each.value.reviewers.teams,
      branch          = compact([each.value.deployment_branch_policy.branch, local.repo.default_branch])[0],
      runs_on         = each.value.runner_group,
      aws_auth        = var.composite_action_repos.aws_auth,
      gh_auth         = var.composite_action_repos.gh_auth,
      setup_terraform = var.composite_action_repos.setup_terraform,
      terraform_init  = var.composite_action_repos.terraform_init,
      terraform_plan  = var.composite_action_repos.terraform_plan,
      terraform_apply = var.composite_action_repos.terraform_apply,
      checkout        = var.composite_action_repos.checkout,
      environment     = lookup(github_repository_environment.this, each.value.name).environment
      backend_config  = each.value.state_config.set_backend ? "/backend-configs/${each.key}.tf" : "backend.tf"
      cache_bucket    = each.value.cache_bucket
      s3_cleanup      = var.composite_action_repos.s3_cleanup
      working_dir     = var.repo.working_dir
      vars = distinct(concat(
        [for var in var.repo.vars : var.name],
        [for var in each.value.vars : var.name]
      ))
      secrets = distinct(concat(
        [for secret in var.repo.secrets : secret.name],
        [for secret in each.value.secrets : secret.name]
      ))
    }
  )
  branch = local.repo.default_branch
  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}

# Resource to create a GitHub repository file for the App workflow
resource "github_repository_file" "standalone_app" {
  for_each            = var.standalone ? tomap({ for env in var.environments : env.name => env }) : {}
  repository          = local.repo.name
  file                = ".github/workflows/app-${each.value.name}.yml"
  overwrite_on_create = false
  content = templatefile(
    "${path.module}/workflow-templates/standalone/app.tftpl",
    {
      repo_name       = local.repo.name,
      repo_org        = var.repo.repo_org,
      reviewers       = each.value.reviewers.teams,
      branch          = compact([each.value.deployment_branch_policy.branch, local.repo.default_branch])[0],
      runs_on         = each.value.runner_group,
      aws_auth        = var.composite_action_repos.aws_auth,
      gh_auth         = var.composite_action_repos.gh_auth,
      setup_terraform = var.composite_action_repos.setup_terraform,
      terraform_init  = var.composite_action_repos.terraform_init,
      terraform_plan  = var.composite_action_repos.terraform_plan,
      terraform_apply = var.composite_action_repos.terraform_apply,
      checkout        = var.composite_action_repos.checkout,
      environment     = lookup(github_repository_environment.this, each.value.name).environment
      backend_config  = each.value.state_config.set_backend ? "/backend-configs/${each.key}.tf" : "backend.tf"
      cache_bucket    = each.value.cache_bucket
      s3_cleanup      = var.composite_action_repos.s3_cleanup
      working_dir     = var.repo.working_dir
      app_dir         = var.repo.app_dir
      vars = distinct(concat(
        [for var in var.repo.vars : var.name],
        [for var in each.value.vars : var.name]
      ))
      secrets = distinct(concat(
        [for secret in var.repo.secrets : secret.name],
        [for secret in each.value.secrets : secret.name]
      ))
    }
  )
  branch = local.repo.default_branch
  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}

# Copy setup-aws.yml
resource "github_repository_file" "standalone_setup_aws_action" {
  count               = var.standalone ? 1 : 0
  repository          = local.repo.name
  file                = ".github/actions/setup-aws/action.yml"
  overwrite_on_create = true
  content = templatefile(
    "${path.module}/workflow-templates/standalone/actions/setup-aws.tftpl",
    {
      name = local.repo.name
    }
  )
}

# Copy setup-tf-cache.yml
resource "github_repository_file" "standalone_setup_tf_cache_action" {
  count               = var.standalone ? 1 : 0
  repository          = local.repo.name
  file                = ".github/actions/setup-tf-cache/action.yml"
  overwrite_on_create = true
  content = templatefile(
    "${path.module}/workflow-templates/standalone/actions/setup-tf-cache.tftpl",
    {
      name = local.repo.name
    }
  )
}

resource "github_repository_file" "main_tf" {
  count = var.standalone ? 1 : 0

  repository          = local.repo.name
  file                = "${var.repo.working_dir}/live/main.tf"
  overwrite_on_create = true
  content             = <<EOT
resource "null_resource" "default" {
  provisioner "local-exec" {
    command = "echo 'Hello World'"
  }
}
EOT
  lifecycle {
    ignore_changes = [
      branch,
      content
    ]
  }
}
