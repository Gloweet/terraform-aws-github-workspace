# valid_string_concat.tftest.hcl
variables {
  name                    = "github-repo-test"
  repo_org                = "HappyPathway"
  force_name              = true
  github_is_private       = false
  enforce_prs             = false
  archive_on_destroy      = false
  github_org_teams        = []
  admin_teams             = ["test-team"]
  github_repo_description = "Test repository"
  github_repo_topics      = ["test", "terraform"]
  create_repo             = true
  secrets = [
    {
      name  = "TEST_SECRET"
      value = "secret-value"
    }
  ]
  vars = [
    {
      name  = "TEST_VAR"
      value = "test-value"
    }
  ]
  extra_files = [
    {
      path    = "test.md"
      content = "Test content"
    }
  ]
}

# Test repository creation first
run "create_new_repository" {
  command = apply
}

# Then test repository data source
run "verify_data_source" {
  variables {
    create_repo = false
  }
  command = plan
  assert {
    condition     = data.github_repository.existing[0].name == var.name
    error_message = "Data source repository name does not match input"
  }
}

# Now test other components that depend on the repository existing
run "repo_tests" {
  command = plan
  assert {
    condition     = github_repository.repo[0].name == "github-repo-test"
    error_message = "Github Repo name did not match expected"
  }
}

run "verify_branch_protection" {
  variables {
    github_default_branch                  = "main"
    enforce_prs                            = true
    github_is_private                      = false
    github_required_approving_review_count = 2
  }
  command = plan
  assert {
    condition     = github_branch_protection.protection["main"].pattern == "main"
    error_message = "Branch protection pattern should be main"
  }
  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].required_approving_review_count == 2
    error_message = "Should require 2 review approvals"
  }
}

# Test branch protection with different configurations
run "verify_branch_protection_with_strict_settings" {
  variables {
    github_default_branch                   = "main"
    enforce_prs                             = true
    github_is_private                       = false
    github_required_approving_review_count  = 2
    github_enforce_admins_branch_protection = true
    github_dismiss_stale_reviews            = true
    github_require_code_owner_reviews       = true
    require_signed_commits                  = true
    pull_request_bypassers                  = ["test-user"]
    required_status_checks = {
      strict   = true
      contexts = ["test/build", "test/lint"]
    }
  }

  command = plan

  assert {
    condition     = github_branch_protection.protection["main"].pattern == "main"
    error_message = "Branch protection pattern should be main"
  }

  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].required_approving_review_count == 2
    error_message = "Should require 2 review approvals"
  }

  assert {
    condition     = github_branch_protection.protection["main"].enforce_admins == true
    error_message = "Should enforce branch protection on admins"
  }

  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].dismiss_stale_reviews == true
    error_message = "Should dismiss stale reviews"
  }

  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].require_code_owner_reviews == true
    error_message = "Should require code owner reviews"
  }

  assert {
    condition     = github_branch_protection.protection["main"].require_signed_commits == true
    error_message = "Should require signed commits"
  }

  assert {
    condition     = github_branch_protection.protection["main"].required_status_checks[0].strict == true
    error_message = "Should require strict status checks"
  }

  assert {
    condition     = length(github_branch_protection.protection["main"].required_status_checks[0].contexts) == 2
    error_message = "Should have exactly 2 required status check contexts"
  }
}

# Test edge cases for branch protection
run "verify_branch_protection_with_minimal_settings" {
  variables {
    enforce_prs                             = true
    github_default_branch                   = "main"
    github_required_approving_review_count  = 0
    github_enforce_admins_branch_protection = false
    github_dismiss_stale_reviews            = false
    github_require_code_owner_reviews       = false
    required_status_checks                  = null
  }

  command = plan

  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].required_approving_review_count == 0
    error_message = "Should allow zero required approvals"
  }

  assert {
    condition     = github_branch_protection.protection["main"].enforce_admins == false
    error_message = "Should not enforce on admins when disabled"
  }

  assert {
    condition     = length(github_branch_protection.protection["main"].required_status_checks) == 0
    error_message = "Should not have required status checks when null"
  }
}

# Test branch protection disabled
run "verify_branch_protection_disabled" {
  variables {
    enforce_prs           = false
    github_default_branch = "main"
  }

  command = plan

  assert {
    condition     = length(keys(github_branch_protection.protection)) == 0
    error_message = "Branch protection should not be created when enforce_prs is false"
  }
}

run "verify_repository_files" {
  command = plan
  assert {
    condition     = github_repository_file.extra_files["test.md"].file == "test.md"
    error_message = "Extra file should be created"
  }
  assert {
    condition     = github_repository_file.extra_files["test.md"].content == "Test content"
    error_message = "Extra file content should match input"
  }
}

run "verify_team_access" {
  command = plan
  assert {
    condition     = github_team_repository.admin["test-team"].permission == "admin"
    error_message = "Team should have admin access"
  }
}

run "verify_action_secrets" {
  command = plan
  assert {
    condition     = github_actions_secret.secret["TEST_SECRET"].secret_name == "TEST_SECRET"
    error_message = "Action secret should be created"
  }
  assert {
    condition     = github_actions_variable.variable["TEST_VAR"].variable_name == "TEST_VAR"
    error_message = "Action variable should be created"
  }
}

# Test repository visibility settings
run "verify_private_repository" {
  variables {
    github_is_private       = true
    github_repo_description = "Private repository test"
    vulnerability_alerts    = true
    security_and_analysis = {
      advanced_security = {
        status = "enabled"
      }
      secret_scanning = {
        status = "enabled"
      }
      secret_scanning_push_protection = {
        status = "enabled"
      }
    }
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].visibility == "private"
    error_message = "Repository should be private"
  }

  assert {
    condition     = github_repository.repo[0].security_and_analysis[0].advanced_security[0].status == "enabled"
    error_message = "Advanced security should be enabled for private repo"
  }

  assert {
    condition     = github_repository.repo[0].vulnerability_alerts == true
    error_message = "Vulnerability alerts should be enabled"
  }
}

run "verify_public_repository" {
  variables {
    github_is_private         = false
    github_repo_description   = "Public repository test"
    vulnerability_alerts      = true
    github_has_wiki           = true
    github_has_issues         = true
    github_has_projects       = true
    github_has_discussions    = true
    github_allow_merge_commit = true
    github_allow_squash_merge = true
    github_allow_rebase_merge = true
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].visibility == "public"
    error_message = "Repository should be public"
  }

  assert {
    condition     = github_repository.repo[0].has_wiki
    error_message = "Wiki should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].has_issues
    error_message = "Issues should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].has_projects
    error_message = "Projects should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].has_discussions
    error_message = "Discussions should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].allow_merge_commit
    error_message = "Merge commits should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].allow_squash_merge
    error_message = "Squash merges should be enabled for public repo"
  }

  assert {
    condition     = github_repository.repo[0].allow_rebase_merge
    error_message = "Rebase merges should be enabled for public repo"
  }
}

# Test visibility transitions
run "verify_visibility_transition_to_private" {
  variables {
    github_is_private = false
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].visibility == "public"
    error_message = "Should be public"
  }
}

run "verify_visibility_transition_from_public" {
  variables {
    github_is_private = true
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].visibility == "private"
    error_message = "Should transition to private"
  }
}

# Test security features based on visibility
run "verify_security_features_private" {
  variables {
    github_is_private = true
    security_and_analysis = {
      advanced_security = {
        status = "enabled"
      }
      secret_scanning = {
        status = "enabled"
      }
    }
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].security_and_analysis[0].advanced_security[0].status == "enabled"
    error_message = "Advanced security should be available for private repo"
  }
}

run "verify_security_features_public" {
  variables {
    github_is_private = false
    security_and_analysis = {
      secret_scanning = {
        status = "enabled"
      }
    }
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].security_and_analysis[0].advanced_security[0].status == "disabled"
    error_message = "Advanced security should not be available for public repo"
  }
}

# Test archive behavior with branch protection
run "verify_archive_with_branch_protection" {
  variables {
    enforce_prs           = true
    archived              = true
    github_default_branch = "main"
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].archived == true
    error_message = "Repository should be archived"
  }
}

run "verify_outputs" {
  command = plan
  assert {
    condition     = output.github_repo.name == var.name
    error_message = "Output repository name does not match input"
  }
  assert {
    condition     = output.ssh_clone_url != ""
    error_message = "SSH clone URL should not be empty"
  }
  assert {
    condition     = output.node_id != ""
    error_message = "Node ID should not be empty"
  }
  assert {
    condition     = output.full_name != ""
    error_message = "Full name should not be empty"
  }
  assert {
    condition     = output.repo_id != null
    error_message = "Repository ID should not be null"
  }
  assert {
    condition     = output.html_url != ""
    error_message = "HTML URL should not be empty"
  }
  assert {
    condition     = output.http_clone_url != ""
    error_message = "HTTP clone URL should not be empty"
  }
  assert {
    condition     = output.git_clone_url != ""
    error_message = "Git clone URL should not be empty"
  }
  assert {
    condition     = output.visibility == "public"
    error_message = "Visibility should be public"
  }
  assert {
    condition     = output.default_branch == "main"
    error_message = "Default branch should be 'main'"
  }
  assert {
    condition     = length(output.topics) == 2
    error_message = "Should have exactly 2 topics"
  }
}

# Test repository settings inheritance
run "verify_settings_inheritance" {
  variables {
    name                                   = "test-inheritance"
    repo_org                               = "TestOrg"
    github_is_private                      = true
    enforce_prs                            = true
    github_required_approving_review_count = 2
    # Don't set other settings to test defaults
  }

  command = plan

  assert {
    condition     = github_repository.repo[0].allow_squash_merge == true
    error_message = "Should inherit default allow_squash_merge setting"
  }

  assert {
    condition     = github_repository.repo[0].allow_merge_commit == false
    error_message = "Should inherit default allow_merge_commit setting"
  }

  assert {
    condition     = github_repository.repo[0].allow_rebase_merge == false
    error_message = "Should inherit default allow_rebase_merge setting"
  }

  assert {
    condition     = github_repository.repo[0].delete_branch_on_merge == true
    error_message = "Should inherit default delete_branch_on_merge setting"
  }
}

# Test complete repository configuration
run "verify_complete_repository_config" {
  variables {
    name                                    = "test-complete-config"
    repo_org                                = "TestOrg"
    github_is_private                       = false
    github_repo_description                 = "Complete configuration test"
    github_repo_topics                      = ["test", "complete", "config"]
    github_has_issues                       = true
    github_has_wiki                         = true
    github_has_projects                     = true
    github_has_discussions                  = true
    github_auto_init                        = true
    github_allow_merge_commit               = true
    github_allow_squash_merge               = true
    github_allow_rebase_merge               = true
    github_allow_auto_merge                 = true
    github_default_branch                   = "main"
    vulnerability_alerts                    = true
    enforce_prs                             = true
    github_required_approving_review_count  = 2
    github_enforce_admins_branch_protection = true
    require_signed_commits                  = true
    security_and_analysis = {
      advanced_security = {
        status = "enabled"
      }
      secret_scanning = {
        status = "enabled"
      }
      secret_scanning_push_protection = {
        status = "enabled"
      }
    }
    admin_teams       = ["test-team"] # Changed from "admins" to match real team name
    template_repo_org = "HappyPathway"
    template_repo     = "template-dockerhub-container-workspace"
  }

  command = plan

  assert {
    condition = alltrue([
      github_repository.repo[0].name == "test-complete-config",
      github_repository.repo[0].has_issues == true,
      github_repository.repo[0].has_wiki == true,
      github_repository.repo[0].has_projects == true,
      github_repository.repo[0].has_discussions == true,
      github_repository.repo[0].allow_auto_merge == true,
      github_repository.repo[0].visibility == "public",
      github_repository.repo[0].vulnerability_alerts == true,
      can(github_repository.repo[0].security_and_analysis[0].advanced_security[0].status) &&
      github_repository.repo[0].security_and_analysis[0].advanced_security[0].status == "enabled",
      github_repository.repo[0].security_and_analysis[0].secret_scanning[0].status == "enabled",
      github_repository.repo[0].security_and_analysis[0].secret_scanning_push_protection[0].status == "enabled"
    ])
    error_message = "All repository settings should be applied correctly"
  }

  assert {
    condition     = length(github_repository.repo[0].topics) == 3
    error_message = "Should have exactly 3 topics"
  }

  assert {
    condition     = github_branch_protection.protection["main"].required_pull_request_reviews[0].required_approving_review_count == 2
    error_message = "Should require 2 approvals"
  }
}

