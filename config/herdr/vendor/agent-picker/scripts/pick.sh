#!/usr/bin/env bash
# List every Herdr agent, then focus the selected agent's exact pane.
set -euo pipefail

herdr="${HERDR_BIN_PATH:-herdr}"
plugin_root="${HERDR_PLUGIN_ROOT:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

fzf_bin="$(command -v fzf || true)"
if [[ -z "$fzf_bin" && -x /opt/homebrew/bin/fzf ]]; then
  fzf_bin=/opt/homebrew/bin/fzf
fi
if [[ -z "$fzf_bin" ]]; then
  printf 'agent-picker: fzf not found\n' >&2
  exit 1
fi

workspace_json="$("$herdr" workspace list)" || {
  printf 'agent-picker: could not list workspaces\n' >&2
  exit 1
}
agent_json="$("$herdr" agent list)" || {
  printf 'agent-picker: could not list agents\n' >&2
  exit 1
}
rows="$(printf '%s\n%s\n' "$workspace_json" "$agent_json" \
  | awk -f "$plugin_root/scripts/json.awk" -f "$plugin_root/scripts/format-agents.awk")"

[[ -n "$rows" ]] || exit 0

# This picker selects Herdr rows, not files. Do not inherit the user's global
# fzf preview command: file previewers such as bat receive a row as their path.
preview_command="$(printf 'bash %q {2}' "$plugin_root/scripts/preview.sh")"
selection="$(printf '%s\n' "$rows" | FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= "$fzf_bin" \
  --reverse \
  --no-multi \
  --cycle \
  --tiebreak=begin \
  --delimiter=$'\t' \
  --with-nth=1 \
  --prompt='agent> ' \
  --header='enter: focus   esc: cancel' \
  --preview="$preview_command" \
  --preview-window='right:55%:wrap')" || exit 0

pane_id="${selection##*$'\t'}"
pane_id="${pane_id%% *}"

[[ "$pane_id" =~ ^[A-Za-z0-9_.:-]+$ ]] || {
  printf 'agent-picker: invalid pane id\n' >&2
  exit 1
}

# pane.focus switches workspace, tab, and pane together. Herdr does not expose
# this exact operation through its CLI, so use its Unix-domain control socket.
if [[ -z "${HERDR_SOCKET_PATH:-}" || ! -S "$HERDR_SOCKET_PATH" ]]; then
  printf 'agent-picker: Herdr control socket unavailable\n' >&2
  exit 1
fi

nc_bin="$(command -v nc || true)"
[[ -n "$nc_bin" ]] || {
  printf 'agent-picker: nc not found\n' >&2
  exit 1
}

response="$(printf '{"id":"agent-picker","method":"pane.focus","params":{"pane_id":"%s"}}\n' "$pane_id" \
  | "$nc_bin" -U "$HERDR_SOCKET_PATH" -w 5 2>/dev/null || true)"

if [[ "$response" == *'"result":'* ]]; then
  exit 0
fi

printf 'agent-picker: failed to focus %s\n' "$pane_id" >&2
exit 1
