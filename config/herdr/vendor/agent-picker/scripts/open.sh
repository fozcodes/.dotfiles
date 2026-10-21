#!/usr/bin/env bash
# Open the agent picker in a session-modal Herdr popup.
set -euo pipefail

exec "${HERDR_BIN_PATH:-herdr}" plugin pane open \
  --plugin foz.agent-picker \
  --entrypoint picker
