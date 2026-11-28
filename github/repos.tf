# Repository settings, default-branch rulesets and GitHub Pages for the
# repositories under `managed` in repos.jsonnet (compiled by //:repos to
# ../repos.json), with temporary overrides in as_found.tf.

locals {
  repos = jsondecode(file("${path.module}/../repos.json")).managed

  # GitHub Actions' app ID. Used as integration_id on required checks so a
  # status with the same name from anywhere else does not count, except for
  # repositories in checks_from_any_source.
  github_actions_app_id = 15368
}

# Shared repository settings plus per-repository description, wiki, visibility
# and homepage. By default the homepage is https://<pages.domain> when Pages is
# set and empty otherwise; temporary overrides live in as_found.tf.
resource "github_repository" "this" {
  for_each = local.repos

  name         = each.key
  description  = try(each.value.description, null)
  homepage_url = try(local.as_found[each.key].homepage_url, "https://${each.value.pages.domain}", null)
  visibility   = try(each.value.visibility, "public")

  has_issues      = true
  has_projects    = true
  has_wiki        = try(each.value.wiki, true)
  has_discussions = false

  allow_merge_commit          = true
  allow_squash_merge          = true
  allow_rebase_merge          = true
  allow_auto_merge            = true
  allow_update_branch         = false
  delete_branch_on_merge      = true
  web_commit_signoff_required = false
  merge_commit_title          = "MERGE_MESSAGE"
  merge_commit_message        = "PR_TITLE"
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"

  # Secret scanning needs GitHub Advanced Security on a private repository.
  dynamic "security_and_analysis" {
    for_each = try(each.value.visibility, "public") == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }
}

# Protects the default branch against deletion and force pushes. Pull requests
# are required unless direct_pushes is set; required_checks, when non-empty,
# must come from GitHub Actions except for repositories in
# checks_from_any_source.
resource "github_repository_ruleset" "default_branch" {
  for_each = local.repos

  name        = "main"
  repository  = github_repository.this[each.key].name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    dynamic "pull_request" {
      for_each = try(each.value.direct_pushes, false) ? [] : [1]
      content {
        allowed_merge_methods             = ["merge", "squash", "rebase"]
        required_approving_review_count   = 0
        dismiss_stale_reviews_on_push     = false
        require_code_owner_review         = false
        require_last_push_approval        = false
        required_review_thread_resolution = false
      }
    }

    dynamic "required_status_checks" {
      for_each = length(each.value.required_checks) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = false
        do_not_enforce_on_create             = false

        dynamic "required_check" {
          for_each = each.value.required_checks
          content {
            context        = required_check.value
            integration_id = contains(local.checks_from_any_source, each.key) ? 0 : local.github_actions_app_id
          }
        }
      }
    }
  }
}

# Workflow-built GitHub Pages with custom domain and enforced HTTPS for
# repositories that set `pages`.
resource "github_repository_pages" "this" {
  for_each = { for name, repo in local.repos : name => repo if can(repo.pages) }

  repository     = github_repository.this[each.key].name
  build_type     = "workflow"
  cname          = each.value.pages.domain
  https_enforced = true
}
