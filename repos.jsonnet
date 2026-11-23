// Every repository in the benbirt account that is not archived, and how each
// one differs from the rest. `bazel build //:repos` compiles this to
// bazel-bin/repos.json, which CI checks against repos.schema.json; the schema
// describes the fields and gives their defaults.
//
// A repository under `managed` follows the shared scheme. One under
// `unmanaged` is left alone, with the reason.

local fork = 'Fork, kept for pull requests to the upstream repository.';

{
  managed: {
    'bazel-style': {
      build: 'bazel',
      required_checks: ['test'],
      dependabot: ['npm', 'pip', 'github-actions'],
    },

    'benbirt.io': {
      build: 'bazel',
      required_checks: ['build'],
      dependabot: ['opentofu', 'github-actions'],
      pages: { target: '//site:public', domain: 'benbirt.io' },
      tofu: ['//infra:infra'],
    },

    eavesbard: {
      build: 'bazel',
      required_checks: ['build'],
      dependabot: ['npm', 'opentofu', 'github-actions'],
      pages: { target: '//src:site', domain: 'eavesbard.com' },
      tofu: ['//dns:dns', '//posthog:posthog'],
    },

    'flip7-scorecard': {
      build: 'bazel',
      required_checks: ['test'],
      dependabot: ['github-actions'],
      pages: { target: '//:public', domain: 'flip7.benbirt.io' },
    },

    'github-infra': {
      build: 'bazel',
      required_checks: ['lint'],
      dependabot: ['github-actions'],
    },

    rules_tofu: {
      build: 'bazel',
      required_checks: [
        'lint',
        'build-and-test (ubuntu-latest, pinned)',
        'build-and-test (ubuntu-latest, 8.5.0)',
        'build-and-test (macos-latest, pinned)',
        'build-and-test (macos-latest, 8.5.0)',
      ],
      dependabot: ['gomod', 'opentofu', 'github-actions'],
      bazel_updates: {
        // The non-dev deps are floors for every downstream module: under
        // Bazel's minimal version selection, bumping them here would force
        // the same versions on users.
        skip_modules: ['platforms', 'rules_go', 'gazelle'],
        // CI requires the nested workspaces' copies to match the root file.
        bazelversion_files: [
          '.bazelversion',
          'e2e/*/.bazelversion',
          'tests/integration/*/.bazelversion',
        ],
        // A library: the pull requests wait for a person to merge them.
        auto_merge: false,
      },
    },

    'song-of-time': {
      visibility: 'private',
      build: 'nix',
      required_checks: ['termina', 'windfall'],
      dependabot: ['github-actions', 'gomod'],
    },

    'tlog-viewer': {
      build: 'bazel',
      required_checks: ['test'],
      dependabot: ['npm', 'gomod', 'github-actions'],
      pages: { target: '//:site', domain: 'tlog.benbirt.io' },
    },
  },

  unmanaged: {
    '2dRPG': 'No ruleset or shared automation; last pushed in July 2026.',
    C2SP: fork,
    'bazel-central-registry': fork,
    cv: 'No ruleset or shared automation; last pushed in May 2026.',
    'git-witness': 'No ruleset or shared automation.',
    rules_tinygo: "Fork; its workflows are the upstream repository's.",
    tessera: fork,
    'transparency-dev-formats': fork,
  },
}
