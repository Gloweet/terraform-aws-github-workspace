locals {
  ai_harness_enabled = var.standalone && var.repo.ai_harness

  # The agents run through the LiteLLM gateway, which only resolves from the
  # self-hosted runner. `ai_harness_runner` accepts a label string or a list.
  ai_harness_runs_on = (
    var.repo.ai_harness_runner == null ? ["self-hosted", "linux", "x64"] :
    can(tolist(var.repo.ai_harness_runner)) ? tolist(var.repo.ai_harness_runner) : [tostring(var.repo.ai_harness_runner)]
  )

  ai_harness_branch = local.repo.default_branch

  # Agents, skills, commands and scripts are copied verbatim: they carry no
  # repository-specific value. The three workflows and the setup action are
  # templates.
  ai_harness_static_files = {
    ".agents/AGENT-MANIFEST.md"                    = "AGENT-MANIFEST.md"
    ".agents/skills/develop-ticket/SKILL.md"       = "skills/develop-ticket/SKILL.md"
    ".agents/skills/feature-brainstorm/SKILL.md"   = "skills/feature-brainstorm/SKILL.md"
    ".agents/skills/review-pr/SKILL.md"            = "skills/review-pr/SKILL.md"
    ".agents/skills/review-code-quality/SKILL.md"  = "skills/review-code-quality/SKILL.md"
    ".agents/skills/review-security/SKILL.md"      = "skills/review-security/SKILL.md"
    ".agents/skills/review-performance/SKILL.md"   = "skills/review-performance/SKILL.md"
    ".agents/skills/review-documentation/SKILL.md" = "skills/review-documentation/SKILL.md"
    ".opencode/opencode.jsonc"                     = "opencode.jsonc"
    ".opencode/.gitignore"                         = "gitignore"
    ".opencode/commands/ai-review.md"              = "commands/ai-review.md"
    ".opencode/commands/ai-develop.md"             = "commands/ai-develop.md"
    ".opencode/commands/ai-autofix.md"             = "commands/ai-autofix.md"
    ".opencode/agents/develop-coordinator.md"      = "agents/develop-coordinator.md"
    ".opencode/agents/review-coordinator.md"       = "agents/review-coordinator.md"
    ".opencode/agents/feature-brainstormer.md"     = "agents/feature-brainstormer.md"
    ".opencode/agents/review-code-quality.md"      = "agents/review-code-quality.md"
    ".opencode/agents/review-security.md"          = "agents/review-security.md"
    ".opencode/agents/review-performance.md"       = "agents/review-performance.md"
    ".opencode/agents/review-documentation.md"     = "agents/review-documentation.md"
    ".github/actions/setup-opencode/action.yml"    = "actions/setup-opencode/action.yml"
    "scripts/ai-model-run.sh"                      = "scripts/ai-model-run.sh"
    "scripts/ai-autofix.sh"                        = "scripts/ai-autofix.sh"
    "scripts/linear.mjs"                           = "scripts/linear.mjs"
  }
}

# Agents, skills, commands, scripts and the setup action: written once, then
# owned by the target repo (they are tuned per repository, so Terraform must not
# rewrite hand edits).
resource "github_repository_file" "ai_harness_static" {
  for_each            = local.ai_harness_enabled ? local.ai_harness_static_files : {}
  repository          = local.repo.name
  file                = each.key
  overwrite_on_create = false
  content             = file("${path.module}/workflow-templates/ai-harness/${each.value}")
  branch              = local.ai_harness_branch

  lifecycle {
    ignore_changes = [
      branch,
      content,
    ]
  }
}

# Ticket -> PR workflow.
resource "github_repository_file" "ai_harness_develop_ticket" {
  count               = local.ai_harness_enabled ? 1 : 0
  repository          = local.repo.name
  file                = ".github/workflows/develop-ticket.yml"
  overwrite_on_create = false
  content = templatefile(
    "${path.module}/workflow-templates/ai-harness/workflows/develop-ticket.tftpl",
    {
      branch  = local.ai_harness_branch
      model   = var.repo.ai_harness_model
      runs_on = jsonencode(local.ai_harness_runs_on)
    }
  )
  branch = local.ai_harness_branch

  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}

# Weekly feature brainstorm workflow.
resource "github_repository_file" "ai_harness_feature_brainstorm" {
  count               = local.ai_harness_enabled ? 1 : 0
  repository          = local.repo.name
  file                = ".github/workflows/feature-brainstorm.yml"
  overwrite_on_create = false
  content = templatefile(
    "${path.module}/workflow-templates/ai-harness/workflows/feature-brainstorm.tftpl",
    {
      model   = var.repo.ai_harness_model
      runs_on = jsonencode(local.ai_harness_runs_on)
    }
  )
  branch = local.ai_harness_branch

  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}

# PR review workflow, triggered by the `ai` label or workflow_dispatch.
resource "github_repository_file" "ai_harness_review" {
  count               = local.ai_harness_enabled ? 1 : 0
  repository          = local.repo.name
  file                = ".github/workflows/ai-review.yml"
  overwrite_on_create = false
  content = templatefile(
    "${path.module}/workflow-templates/ai-harness/workflows/ai-review.tftpl",
    {
      model   = var.repo.ai_harness_model
      runs_on = jsonencode(local.ai_harness_runs_on)
    }
  )
  branch = local.ai_harness_branch

  lifecycle {
    ignore_changes = [
      branch,
    ]
  }
}
