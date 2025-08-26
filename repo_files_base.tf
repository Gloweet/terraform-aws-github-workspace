locals {
  # Create a map of environment-specific backend configurations
  environment_specific_backend_configs = {
    for env in var.environments : env.name => merge(
      env.state_config,
      {
        path = "${var.repo.working_dir}/backend-configs/${env.name}.tf",
        key  = "${env.state_config.key_prefix}/${env.name}.tfstate",
      }
    )
    if env.state_config.set_backend
  }

  # Global backend configuration
  global_backend_config = merge(
    var.state_config,
    {
      path = "backend.tf",
      key  = "${var.state_config.key_prefix}/terraform.tfstate",
    }
  )

  # Merge environment-specific and global backend configurations
  backend_configs = merge(
    local.environment_specific_backend_configs,
    var.state_config.set_backend ? { "global" = local.global_backend_config } : {}
  )
}

# Resource to create a GitHub repository file for Terraform init workflow
resource "github_repository_file" "env_backend_tf" {
  for_each            = tomap(local.backend_configs)
  repository          = local.repo.name
  file                = each.value.path
  overwrite_on_create = true
  content = templatefile(
    "${path.module}/workflow-templates/backend.tpl",
    {
      bucket         = each.value.bucket,
      key            = each.value.key,
      region         = each.value.region,
      dynamodb_table = each.value.dynamodb_table
    }
  )
}

resource "github_repository_file" "varfiles" {
  for_each            = tomap({ for environment in var.environments : environment.name => environment })
  repository          = local.repo.name
  file                = "${var.repo.working_dir}/varfiles/${each.value.name}.tfvars"
  overwrite_on_create = true
  content             = "# Add Terraform Variables here"
  lifecycle {
    ignore_changes = [
      branch,
      content
    ]
  }
}

resource "github_repository_file" "backend_tf" {
  repository          = local.repo.name
  file                = "${var.repo.working_dir}/backend.tf"
  overwrite_on_create = true
  content             = file("${path.module}/workflow-templates/backend.tf")
  lifecycle {
    ignore_changes = [
      branch,
      content
    ]
  }
}
