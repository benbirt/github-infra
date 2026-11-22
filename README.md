# workflows

Reusable GitHub Actions workflows shared across benbirt's repositories.

## Bazel updates

[`bazel-updates.yml`](.github/workflows/bazel-updates.yml) makes the updates in
a Bazel repository that Dependabot cannot. Dependabot's `bazel` updater
evaluates `MODULE.bazel` without the files that module extensions read
(rules_js reads `package.json`, gazelle's `go_deps` reads `go.mod`), so it
fails wherever those are used.

Each kind of update gets its own branch, `bazel-updates/<kind>`, and pull
request:

- `bazel-version`: the latest Bazel release, written to every file in
  `bazelversion_files`.
- `modules`: each `bazel_dep` in the root `MODULE.bazel` to the newest version
  in the Bazel Central Registry that is not yanked and not a pre-release.
- `node-version`: the newest Node in the major version already in use that
  the pinned rules_nodejs can fetch. It does nothing without rules_nodejs.
- `commits`: each module in the `commits` input, pinned by commit in a
  `git_override`, moved to the head of the branch it follows, on its own
  branch `bazel-updates/<module>`.

Versions only move forwards. `MODULE.bazel.lock` is refreshed with
`bazel mod deps --lockfile_mode=update`. A branch that already holds the same
update on top of the default branch is left alone, so a pull request waiting
on CI is not restarted every day.

Only the root `MODULE.bazel` is edited. Modules nested in the repository (such
as integration-test workspaces) keep their own `bazel_dep` versions.

### Inputs

| Input | Default | Meaning |
| --- | --- | --- |
| `updates` | `bazel-version modules node-version` | Which of `bazel-version`, `modules`, `node-version` and `commits` to make, separated by spaces. |
| `skip_modules` | none | `bazel_dep` names never to bump, separated by spaces. Modules named in an override are always skipped. |
| `bazelversion_files` | `.bazelversion` | The `.bazelversion` files to keep identical, separated by spaces. Glob patterns are expanded. |
| `commits` | none | Modules followed by commit, one per line: the module name and the branch to follow. The remote is the one in the module's `git_override`. Needs `commits` in `updates`. |
| `auto_merge` | `true` | Whether to turn on auto-merge (squash) once the pull request is opened. |

### Token

The workflow needs an `AUTOMATION_TOKEN` secret: a fine-grained personal
access token with read and write access to **Contents** and **Pull requests**
in the calling repository. `GITHUB_TOKEN` will not do, because its pushes and
merges trigger no workflows, so CI would not run on the pull request. The token
is given only to the step that pushes and opens the pull request. The steps
that run Bazel and module extensions never see it.

Auto-merge also needs **Allow auto-merge** turned on in the repository's
settings.

### Example caller

`.github/workflows/bazel-updates.yaml`:

```yaml
name: Bazel updates

on:
  schedule:
    - cron: "17 5 * * *"
  workflow_dispatch:

permissions:
  contents: read

jobs:
  bazel-updates:
    uses: benbirt/workflows/.github/workflows/bazel-updates.yml@<commit sha> # v1.0.0
    with:
      updates: bazel-version modules node-version commits
      skip_modules: platforms
      commits: |
        rules_tinygo hermetic-embed
    secrets:
      AUTOMATION_TOKEN: ${{ secrets.AUTOMATION_TOKEN }}
```

Pin the workflow by commit SHA with the release tag as a comment. Dependabot's
`github-actions` updater then proposes new releases, updating both the SHA and
the comment. Releases are tagged with full semantic versions (`v1.0.0`) so that
Dependabot can compare them.
