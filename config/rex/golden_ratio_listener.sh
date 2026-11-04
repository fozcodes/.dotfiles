#!/bin/sh

set -u

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
export PATH

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
golden_ratio_script="$script_dir/golden_ratio.lua"
rex_app_binary="$HOME/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"

while true; do
  if [ ! -r "$golden_ratio_script" ]; then
    printf '%s\n' "Rex golden-ratio listener: missing $golden_ratio_script" >&2
    sleep 30
    continue
  fi

  if [ -x "$rex_app_binary" ]; then
    rex_binary="$rex_app_binary"
  elif rex_binary=$(command -v rex 2>/dev/null); then
    :
  else
    printf '%s\n' 'Rex golden-ratio listener: rex is not installed' >&2
    sleep 30
    continue
  fi

  # Do not autostart Rex. The listener connects when the server exists and
  # reconnects after its server process restarts.
  if "$rex_binary" --autostart=false do "$golden_ratio_script" --all; then
    printf '%s\n' 'Rex golden-ratio listener stopped; restarting' >&2
  fi
  sleep 2
done
