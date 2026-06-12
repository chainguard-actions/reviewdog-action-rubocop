<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-rubocop/v2.21.3

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-rubocop/v2.21.3** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh downloads and pipes a remote install script directly to `sh` without first saving it to a file: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/.../install.sh | sh -s -- ...`. Even though the URL is pinned to a specific commit SHA, piping remote content directly to a shell interpreter is an unsafe pattern that bypasses any opportunity to inspect the downloaded content before execution.

Locations:

- `script.sh:13`

### script-injection (severity: high)

Rule (b): Multiple unquoted shell variable expansions of attacker-controlled inputs in script.sh allow shell metacharacter injection (word splitting, glob expansion, command injection):
1. `for extension in $INPUT_RUBOCOP_EXTENSIONS` (line ~38) — the `rubocop_extensions` input is iterated without quoting, allowing an attacker to inject shell metacharacters.
2. `${INPUT_RUBOCOP_FLAGS}` (line ~95) — the `rubocop_flags` input is passed unquoted to the rubocop command, allowing argument injection.
3. `${INPUT_REVIEWDOG_FLAGS}` (line ~103) — the `reviewdog_flags` input is passed unquoted to reviewdog, allowing argument injection.
4. `${RUBOCOP_EXTENSION_VERSION_FLAG}` (line ~77) — derived from user-controlled extension version input, used unquoted.
All of these env vars are sourced from `inputs.*` via the `env:` block in action.yml and must be double-quoted when expanded in shell.

Locations:

- `script.sh:38`
- `script.sh:77`
- `script.sh:95`
- `script.sh:103`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed script.sh: (1) unsafe-shell: replaced `curl ... | sh` pipe with download-to-tempfile then execute pattern — curl saves to a mktemp file, sh runs it, then rm cleans it up; (2) script-injection: fixed all four unquoted expansions — converted $INPUT_RUBOCOP_EXTENSIONS for-loop to use `read -ra` array with quoted expansion, converted RUBOCOP_EXTENSION_VERSION_FLAG from an unquoted string to a bash array, and converted INPUT_RUBOCOP_FLAGS and INPUT_REVIEWDOG_FLAGS to `read -ra` arrays with quoted array expansions in the rubocop/reviewdog invocation.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed script injection vulnerability in script.sh line 57. The original code interpolated `$INPUT_RUBOCOP_EXTENSION_NAME` unquoted inside a double-quoted string passed to `ruby -ne`, allowing shell metacharacter injection via the `rubocop_extensions` input. The fix restructures the Ruby invocation to: (1) pass the extension name as an environment variable `RUBOCOP_EXTENSION_NAME="$INPUT_RUBOCOP_EXTENSION_NAME"` (properly shell-quoted), (2) use a single-quoted Ruby script so the shell never expands anything inside it, (3) access the value safely inside Ruby via `ENV["RUBOCOP_EXTENSION_NAME"]` with `Regexp.escape()` to prevent regex injection, and (4) use `ARGF.each_line` to replicate the `-n` flag behavior.

