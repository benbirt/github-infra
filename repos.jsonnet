// Unarchived repositories in the benbirt GitHub account.
//
// `managed` repositories follow a shared scheme and record what varies between
// them. `unmanaged` repositories are left alone, each with a reason.
//
// `bazel build //:repos` compiles this file to bazel-bin/repos.json. See
// repos.schema.json for the field definitions and defaults; CI validates the
// compiled JSON against it.

local fork = 'Fork kept for upstream pull requests.';

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

    'git-witness': {
      build: 'none',
      // Its only workflow responds to issues, so nothing runs on pull requests.
      required_checks: [],
      dependabot: ['github-actions'],
      // The cosign workflow commits each checkpoint directly to main.
      direct_pushes: true,
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
        // Non-dev dependencies set version floors for downstream modules: under
        // Bazel's minimal version selection, bumping them forces those versions
        // on users.
        skip_modules: ['platforms', 'rules_go', 'gazelle'],
        // CI requires nested workspaces' .bazelversion files to match the root.
        bazelversion_files: [
          '.bazelversion',
          'e2e/*/.bazelversion',
          'tests/integration/*/.bazelversion',
        ],
        // Update pull requests are merged manually because this is a library.
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
    rules_tinygo: 'Fork; uses upstream workflows.',
    tessera: fork,
    'transparency-dev-formats': fork,
  },
}
