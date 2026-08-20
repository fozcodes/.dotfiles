#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="vim-herdr-navigation"
PLUGIN_DIR="$DOTFILES_DIR/vendor/vim-herdr-navigation"

if ! command -v herdr >/dev/null 2>&1; then
  printf 'herdr is not installed; install it before running %s\n' "$0" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  printf 'jq is required by %s\n' "$PLUGIN_ID" >&2
  exit 1
fi

if [[ ! -f "$PLUGIN_DIR/herdr-plugin.toml" ]]; then
  git -C "$DOTFILES_DIR" submodule update --init -- vendor/vim-herdr-navigation
fi

registered_root="$(herdr plugin list --json \
  | jq -r --arg id "$PLUGIN_ID" '.result.plugins[]? | select(.plugin_id == $id) | .plugin_root' \
  | head -n 1)"

if [[ -n "$registered_root" ]]; then
  if [[ "$registered_root" == "$PLUGIN_DIR" ]]; then
    printf '%s is already linked\n' "$PLUGIN_ID"
    exit 0
  fi

  printf '%s is already registered from %s; unlink it, then rerun %s\n' \
    "$PLUGIN_ID" "$registered_root" "$0" >&2
  exit 1
fi

herdr plugin link "$PLUGIN_DIR"
printf 'linked %s\n' "$PLUGIN_ID"
herdr plugin action list --plugin "$PLUGIN_ID"
