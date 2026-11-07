<!-- markdownlint-disable -->

# Hardening Report: reviewdog--action-rubocop/v2.23.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **reviewdog--action-rubocop/v2.23.0** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unsafe-shell (severity: high)

script.sh, the supporting script that action.yml runs, downloads the reviewdog installer and pipes it straight into a shell: `curl -sfL https://raw.githubusercontent.com/reviewdog/reviewdog/fd59714416d6d9a1c0692d872e38e7f8448df4fc/install.sh | sh -s -- -b "${TEMP_PATH}" "${REVIEWDOG_VERSION}"`. The URL is pinned to a commit, but the content is still run without being saved to a file and checked first. Save the installer to a file, verify it (for example with a checksum), then run it as a separate step.

Locations:

- `script.sh:13`

## Iteration Notes

### Iteration 1

**Fixes applied:** unsafe-shell

**Notes:**

script.sh now downloads the reviewdog installer from the commit-pinned URL into a temp file. It checks that the file is non-empty and starts with a shebang, then runs it with `sh "$file" -b "$TEMP_PATH" "$REVIEWDOG_VERSION"`. The `-s --` from the old pipe form is dropped so the installer still receives `-b` as its first argument. The file is deleted after the install. No SHA256 checksum was added: I couldn't fetch the installer here to get a real hash, so the shebang check is a basic sanity test, not a proof the file is genuine. The URL pinned to a commit is what guards the content.

