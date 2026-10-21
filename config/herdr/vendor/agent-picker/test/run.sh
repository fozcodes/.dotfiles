#!/usr/bin/env bash
set -euo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
actual="$(mktemp)"
trap 'rm -f "$actual"' EXIT

awk \
  -f "$root/scripts/json.awk" \
  -f "$root/scripts/format-agents.awk" \
  "$root/test/fixtures/workspace-list.json" \
  "$root/test/fixtures/agent-list.json" > "$actual"

diff -u "$root/test/expected/agents.txt" "$actual"

grep -Fq 'FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= "$fzf_bin"' "$root/scripts/pick.sh"
grep -Fq -- '--preview="$preview_command"' "$root/scripts/pick.sh"

preview_output="$(HERDR_BIN_PATH=/bin/echo bash "$root/scripts/preview.sh" 'wa1:p2 wa1:t2')"
[[ "$preview_output" == 'pane read wa1:p2 --source recent-unwrapped --lines 60 --format text' ]]

if HERDR_BIN_PATH=/bin/echo bash "$root/scripts/preview.sh" 'invalid pane' >/dev/null 2>&1; then
  printf 'preview accepted an invalid pane id\n' >&2
  exit 1
fi

printf 'agent-picker tests passed\n'
