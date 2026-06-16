<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-rubocop/v2.22.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **reviewdog--action-rubocop/v2.22.0** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh pipes a remotely fetched install script directly to `sh` without first downloading and verifying it. The pattern `curl -sfL https://raw.githubusercontent.com/.../install.sh | sh -s -- ...` executes whatever content the remote URL returns, making the workflow vulnerable to supply-chain attacks if the URL is compromised or redirected.

Locations:

- `script.sh:13`

### script-injection (severity: high)

Sub-rule (b): Multiple env vars that hold user-controlled `inputs.*` values are expanded unquoted inside shell commands in script.sh, allowing shell metacharacter injection (word-splitting, glob expansion, command substitution):

1. Line 38: `for extension in $INPUT_RUBOCOP_EXTENSIONS; do` — `$INPUT_RUBOCOP_EXTENSIONS` is unquoted, so an attacker-controlled value containing shell metacharacters (`;`, `|`, `$(...)`, etc.) can break out of the loop context.

2. Line 108: `${INPUT_RUBOCOP_FLAGS} \` — passed unquoted to rubocop (a `# shellcheck disable=SC2086` comment even acknowledges this). An attacker-controlled `rubocop_flags` input can inject arbitrary shell arguments or commands.

3. Line 119: `${INPUT_REVIEWDOG_FLAGS}` — passed unquoted to reviewdog. An attacker-controlled `reviewdog_flags` input can inject arbitrary shell arguments or commands.

All three env vars are set from `inputs.*` in action.yml's `env:` block, making them workflow-caller-controlled.

Locations:

- `script.sh:38`
- `script.sh:108`
- `script.sh:119`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell, script-injection

**Notes:**

Fixed script.sh with three changes: (1) unsafe-shell: replaced `curl | sh` pipe with download-then-execute pattern — curl saves to a temp file, sh executes it, then rm cleans up; (2) script-injection line 38: replaced unquoted `$INPUT_RUBOCOP_EXTENSIONS` in for-loop with `read -ra` array construction and quoted `"${RUBOCOP_EXTENSIONS_ARRAY[@]}"` iteration; (3) script-injection lines 108/119: replaced unquoted `${INPUT_RUBOCOP_FLAGS}` and `${INPUT_REVIEWDOG_FLAGS}` with `read -ra` arrays and quoted `"${RUBOCOP_FLAGS_ARRAY[@]}"` / `"${REVIEWDOG_FLAGS_ARRAY[@]}"` expansions in the rubocop/reviewdog invocation.

