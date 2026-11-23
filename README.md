# github-infra

The shared configuration of benbirt's repositories: the list of repositories
and the reusable GitHub Actions workflows they call.

## Repositories

[`repos.jsonnet`](repos.jsonnet) lists every repository in the account that is
not archived. A repository under `managed` follows the shared scheme, and its
entry holds everything about it that differs from the others: what builds it,
the checks its pull requests need, its Pages site and the OpenTofu it applies.
One under `unmanaged` is left alone, and its entry says why.

`bazel build //:repos` compiles the list to `bazel-bin/repos.json`.
[`repos.schema.json`](repos.schema.json) describes the fields and their
defaults, and CI checks the compiled list against it.

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
- `commits`: each `git_override` with a `commit` and a `remote`, moved to the
  head of the remote's `main` branch, on its own branch
  `bazel-updates/<module>`. Every module followed by commit is assumed to
  follow `main`; a remote without one fails the job. It does nothing without
  such a `git_override`.

Versions only move forwards. `MODULE.bazel.lock` is refreshed with
`bazel mod deps --lockfile_mode=update`. A branch that already holds the same
update on top of the default branch is left alone, so a pull request waiting
on CI is not restarted every day.

Only the root `MODULE.bazel` is edited. Modules nested in the repository (such
as integration-test workspaces) keep their own `bazel_dep` versions.

### Inputs

| Input | Default | Meaning |
| --- | --- | --- |
| `updates` | `bazel-version modules node-version commits` | Which of `bazel-version`, `modules`, `node-version` and `commits` to make, separated by spaces. |
| `skip_modules` | none | Modules never to update, separated by spaces: neither their `bazel_dep` version nor their `git_override` commit. Modules named in an override never get a registry version. |
| `bazelversion_files` | `.bazelversion` | The `.bazelversion` files to keep identical, separated by spaces. Glob patterns are expanded. |
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
    uses: benbirt/github-infra/.github/workflows/bazel-updates.yml@<commit sha> # v1.1.0
    with:
      skip_modules: platforms
    secrets:
      AUTOMATION_TOKEN: ${{ secrets.AUTOMATION_TOKEN }}
```

Pin the workflow by commit SHA with the release tag as a comment. Dependabot's
`github-actions` updater then proposes new releases, updating both the SHA and
the comment. Releases are tagged with full semantic versions (`v1.1.0`) so that
Dependabot can compare them.
