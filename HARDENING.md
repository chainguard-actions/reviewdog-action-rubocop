<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-rubocop/v2.22.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-rubocop/v2.22.0** was hardened automatically. 4 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remote install script directly to `sh` without first downloading it to a file: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. Even though the URL is pinned to a specific commit SHA, piping remote content directly to a shell interpreter is a dangerous pattern that bypasses any opportunity to inspect the script before execution.

Locations:

- `script.sh:13`

### script-injection (severity: high)

Sub-rule (a): `${{ github.sha }}` is interpolated directly inside `run:` shell command strings in three steps of the `test-only_changed` job. Any `${{ ... }}` expression directly inside a `run:` block is a script-injection risk because the value is substituted into the shell command string before the shell parses it. The offending lines are: `git checkout ${{ github.sha }}` (repeated in three steps).

Locations:

- `.github/workflows/ci.yml:39`
- `.github/workflows/ci.yml:52`
- `.github/workflows/ci.yml:65`

### script-injection (severity: high)

Sub-rule (b): script.sh expands several env vars that hold values from `inputs.*` (set via the action.yml env: block) without double-quoting, allowing shell metacharacter injection: (1) `for extension in $INPUT_RUBOCOP_EXTENSIONS` — unquoted word-splitting of a user-controlled input; (2) `${INPUT_RUBOCOP_FLAGS}` — unquoted expansion passed as rubocop flags; (3) `${INPUT_REVIEWDOG_FLAGS}` — unquoted expansion passed as reviewdog flags. An attacker-controlled caller can inject shell metacharacters (`;`, `|`, `&`, `$(...)`, etc.) through these inputs.

Locations:

- `script.sh:43`
- `script.sh:112`
- `script.sh:119`

### missing-permissions (severity: medium)

None of the workflow files define a `permissions:` key at the top level or at the job level. Without explicit permissions, workflows run with the default (potentially broad) GITHUB_TOKEN permissions. All five workflow files are affected: ci.yml, depup.yml, release.yml, reviewdog.yml, and test_rdjson_formatter.yml.

Locations:

- `.github/workflows/ci.yml:1`
- `.github/workflows/depup.yml:1`
- `.github/workflows/release.yml:1`
- `.github/workflows/reviewdog.yml:1`
- `.github/workflows/test_rdjson_formatter.yml:1`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection, missing-permissions

**Notes:**

Fixed all 4 findings:

1. unsafe-shell (script.sh): Replaced `curl | sh` pipe with download-then-execute pattern: curl downloads to a temp file, sh executes the file, then the temp file is removed.

2. script-injection/ci.yml (3 locations): Moved `${{ github.sha }}` into step-level `env:` blocks as `GIT_SHA`, referenced as `"$GIT_SHA"` in shell commands.

3. script-injection/script.sh (3 locations): (a) `for extension in $INPUT_RUBOCOP_EXTENSIONS` replaced with `IFS=' ' read -ra` array + quoted array expansion; (b) `${INPUT_RUBOCOP_FLAGS}` converted to array `RUBOCOP_FLAGS_ARRAY` with quoted expansion; (c) `${INPUT_REVIEWDOG_FLAGS}` converted to array `REVIEWDOG_FLAGS_ARRAY` with quoted expansion.

4. missing-permissions: Added minimal `permissions:` blocks to all 5 workflow files: ci.yml (contents:read), depup.yml (contents:write + pull-requests:write), release.yml (contents:write), reviewdog.yml (contents:read + pull-requests:write), test_rdjson_formatter.yml (contents:read).

### Iteration 2

**Fixes applied:** script-injection, script-injection

**Notes:**

Fixed two script injection vulnerabilities in script.sh:
1. Line 56: Replaced shell interpolation of $INPUT_RUBOCOP_EXTENSION_NAME into a double-quoted Ruby -ne string with an environment variable approach: RUBY_GEM_NAME is set to the gem name and Ruby uses Regexp.escape(ENV["RUBY_GEM_NAME"]) to safely build the regex pattern, preventing Ruby code injection.
2. Line 80: Replaced the unquoted RUBOCOP_EXTENSION_VERSION_FLAG string variable (which allowed word splitting and metacharacter injection) with a bash array RUBOCOP_EXTENSION_VERSION_ARGS that holds --version and the version value as separate properly-quoted elements, used as "${RUBOCOP_EXTENSION_VERSION_ARGS[@]}" in the gem install command.

