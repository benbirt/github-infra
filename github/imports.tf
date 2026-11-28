# One-off imports that adopt the existing repositories, default-branch rulesets
# and GitHub Pages sites into state on the first apply. Delete this file after
# that apply succeeds.

locals {
  # GitHub ruleset IDs for repositories that already have a default-branch
  # ruleset. git-witness has none yet, so OpenTofu creates it.
  existing_rulesets = {
    "bazel-style"     = 27851245
    "benbirt.io"      = 27262449
    "eavesbard"       = 27835005
    "flip7-scorecard" = 27596809
    "github-infra"    = 27852625
    "rules_tofu"      = 16228920
    "song-of-time"    = 24817500
    "tlog-viewer"     = 27053099
  }
}

import {
  for_each = local.repos
  to       = github_repository.this[each.key]
  id       = each.key
}

import {
  for_each = local.existing_rulesets
  to       = github_repository_ruleset.default_branch[each.key]
  id       = "${each.key}:${each.value}"
}

import {
  for_each = { for name, repo in local.repos : name => repo if can(repo.pages) }
  to       = github_repository_pages.this[each.key]
  id       = each.key
}
