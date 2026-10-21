#!/usr/bin/env bash
# Render the selected agent pane's latest terminal output in fzf's preview.
set -euo pipefail

# fzf quotes each placeholder expansion as one argument. The hidden field
# contains the pane ID followed by the tab ID. Validate that exact shape before
# using the pane ID in a Herdr request.
selection="${1:-}"
[[ "$selection" =~ ^([A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+)\ ([A-Za-z0-9_.-]+:[A-Za-z0-9_.-]+)$ ]] || {
  printf 'agent-picker: invalid pane id\n' >&2
  exit 1
}
pane_id="${BASH_REMATCH[1]}"

exec "${HERDR_BIN_PATH:-herdr}" pane read "$pane_id" \
  --source recent-unwrapped \
  --lines 60 \
  --format text
