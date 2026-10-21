#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VIM_PLUGIN_ID="vim-herdr-navigation"
VIM_PLUGIN_DIR="$DOTFILES_DIR/config/herdr/vendor/vim-herdr-navigation"
AGENT_PICKER_PLUGIN_ID="foz.agent-picker"
AGENT_PICKER_PLUGIN_DIR="$DOTFILES_DIR/config/herdr/vendor/agent-picker"

if ! command -v herdr >/dev/null 2>&1; then
  printf 'herdr is not installed; install it before running %s\n' "$0" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq is required by %s\n' "$0" >&2
  exit 1
fi

if [[ ! -f "$VIM_PLUGIN_DIR/herdr-plugin.toml" ]]; then
  git -C "$DOTFILES_DIR" submodule update --init -- config/herdr/vendor/vim-herdr-navigation
fi

link_plugin() {
  local plugin_id=$1 plugin_dir=$2 registered_root

  if [[ ! -f "$plugin_dir/herdr-plugin.toml" ]]; then
    printf '%s manifest is missing: %s\n' "$plugin_id" "$plugin_dir/herdr-plugin.toml" >&2
    return 1
  fi

  registered_root="$(herdr plugin list --json \
    | jq -r --arg id "$plugin_id" '.result.plugins[]? | select(.plugin_id == $id) | .plugin_root' \
    | head -n 1)"

  if [[ -n "$registered_root" ]]; then
    if [[ "$registered_root" == "$plugin_dir" ]]; then
      printf '%s is already linked\n' "$plugin_id"
      return 0
    fi

    printf '%s is already registered from %s; unlink it, then rerun %s\n' \
      "$plugin_id" "$registered_root" "$0" >&2
    return 1
  fi

  herdr plugin link "$plugin_dir"
  printf 'linked %s\n' "$plugin_id"
}

link_plugin "$VIM_PLUGIN_ID" "$VIM_PLUGIN_DIR"
link_plugin "$AGENT_PICKER_PLUGIN_ID" "$AGENT_PICKER_PLUGIN_DIR"

herdr plugin action list --plugin "$VIM_PLUGIN_ID"
herdr plugin action list --plugin "$AGENT_PICKER_PLUGIN_ID"
