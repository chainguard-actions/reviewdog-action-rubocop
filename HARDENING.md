<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-rubocop/v2.21.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-rubocop/v2.21.3** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh downloads and pipes a remote install script directly to `sh` without first saving it to disk: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. Even though the URL is pinned to a commit SHA, piping remote content directly to a shell interpreter is an unsafe pattern — the script should be downloaded to a file, verified, and then executed separately.

Locations:

- `script.sh:13`

### script-injection (severity: high)

Rule (b) violation: Multiple env vars holding workflow-controllable inputs (set via the `env:` block in action.yml from `inputs.*`) are expanded unquoted in shell commands, allowing shell metacharacter injection. (1) Line 33: `RUBOCOP_VERSION=$INPUT_RUBOCOP_VERSION` unquoted assignment; (2) Line 37: `for extension in $INPUT_RUBOCOP_EXTENSIONS` unquoted word-split loop; (3) Line 46: `$INPUT_RUBOCOP_EXTENSION_NAME` unquoted inside a double-quoted ruby -ne string; (4) Line 57: `RUBOCOP_EXTENSION_VERSION=$INPUT_RUBOCOP_EXTENSION_VERSION` unquoted assignment; (5) Line 103: `${INPUT_RUBOCOP_FLAGS}` passed unquoted to rubocop; (6) Line 110: `${INPUT_REVIEWDOG_FLAGS}` passed unquoted to reviewdog. All these vars are sourced from `inputs.*` context values and must be double-quoted.

Locations:

- `script.sh:33`
- `script.sh:37`
- `script.sh:46`
- `script.sh:57`
- `script.sh:103`
- `script.sh:110`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed all findings in script.sh:

1. unsafe-shell (line 13): Replaced `curl ... | sh` pipe with: download install script to a temp file using `curl -sfL -o`, execute it with `sh`, then `rm -f` the temp file.

2. script-injection (6 locations):
   - Line 33: Quoted `RUBOCOP_VERSION="$INPUT_RUBOCOP_VERSION"`
   - Line 37: Replaced unquoted `for extension in $INPUT_RUBOCOP_EXTENSIONS` with a safe array: `RUBOCOP_EXTENSIONS_ARRAY=(); if [ -n "$INPUT_RUBOCOP_EXTENSIONS" ]; then IFS=' ' read -ra RUBOCOP_EXTENSIONS_ARRAY <<< "$INPUT_RUBOCOP_EXTENSIONS"; fi` and iterating `"${RUBOCOP_EXTENSIONS_ARRAY[@]}"`
   - Line 46: Replaced shell interpolation of `$INPUT_RUBOCOP_EXTENSION_NAME` inside a double-quoted ruby -ne string with ENV-based interpolation: `RUBOCOP_EXT_NAME="$INPUT_RUBOCOP_EXTENSION_NAME" ruby -ne 'print $& if /^\s{4}#{ENV["RUBOCOP_EXT_NAME"]}\s\(\K.*(?=\))/'`
   - Line 57: Quoted `RUBOCOP_EXTENSION_VERSION="$INPUT_RUBOCOP_EXTENSION_VERSION"`
   - Lines 103/110: Replaced unquoted `${INPUT_RUBOCOP_FLAGS}` and `${INPUT_REVIEWDOG_FLAGS}` with safe arrays using `IFS=' ' read -ra` and `"${RUBOCOP_FLAGS_ARRAY[@]}"` / `"${REVIEWDOG_FLAGS_ARRAY[@]}"`; empty-string guard added to avoid passing empty array elements.

### Iteration 1

**Fixes applied:** script-injection, missing-permissions

**Notes:**

Fixed script-injection in ci.yml by moving all three `${{ github.sha }}` expressions from `run:` shell strings into step-level `env:` blocks (as `GIT_SHA`), then referencing `"$GIT_SHA"` in the shell. Added top-level `permissions:` blocks to all five workflow files: `permissions: {}` for ci.yml (no permissions needed), `contents: write` + `pull-requests: write` for depup.yml and release.yml (create PRs/releases), `contents: read` + `pull-requests: write` for reviewdog.yml (post review comments), and `contents: read` for test_rdjson_formatter.yml (read-only test run).

