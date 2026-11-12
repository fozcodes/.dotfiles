# Apply the Ghostty palettes to running Rex terminals

The palettes originally imported on this Mac are named Rex custom themes,
selected as its dark and light themes. Rex stores them in app preferences, not
in dotfiles. The exact original import steps have not been recovered; do not
use the script below as a substitute for a persistent import.

The script below is a separate, temporary alternative: it requests a palette
for each terminal block that exists when it runs. It does **not** add a named
Rex theme or configure new blocks, and an owning client may override the
request. Run it again after Rex creates new terminals if needed.

## Source palettes

- Dark: [`../ghostty/themes/nightfox`](../ghostty/themes/nightfox)
- Light: [`../ghostty/themes/warm-burnout-light`](../ghostty/themes/warm-burnout-light)

Rex's terminal `set_theme` method accepts the foreground, background, cursor,
ANSI palette, and light/dark scheme. It has no selection-color field, so this
procedure does not import Ghostty's selection colors.

## Procedure

1. Start Rex and create or restore the terminal blocks to theme.
2. Save this script as `/tmp/apply-rex-ghostty-theme.sh` on the target machine.
3. Run one of the final two commands: `nightfox` for dark mode or
   `warm_burnout_light` for light mode.

```bash
#!/usr/bin/env bash
set -uo pipefail

command -v rex >/dev/null || { echo 'rex is not on PATH' >&2; exit 1; }
command -v jq >/dev/null || { echo 'jq is not on PATH' >&2; exit 1; }

nightfox='{
  "foreground":"#cdcecf",
  "background":"#192330",
  "cursor":"#cdcecf",
  "scheme":"dark",
  "palette":[
    "0=#393b44", "1=#c94f6d", "2=#81b29a", "3=#dbc074",
    "4=#719cd6", "5=#9d79d6", "6=#63cdcf", "7=#dfdfe0",
    "8=#575860", "9=#d16983", "10=#8ebaa4", "11=#e0c989",
    "12=#86abdc", "13=#baa1e2", "14=#7ad5d6", "15=#e4e4e5"
  ]
}'

warm_burnout_light='{
  "foreground":"#3a3630",
  "background":"#F5EDE0",
  "cursor":"#8a6600",
  "scheme":"light",
  "palette":[
    "0=#3a3630", "1=#b82820", "2=#2d6a14", "3=#8a6000",
    "4=#2060a0", "5=#8a3090", "6=#146858", "7=#c0b8aa",
    "8=#686868", "9=#c83028", "10=#3a7a20", "11=#9a7008",
    "12=#2870b0", "13=#9a38a0", "14=#208870", "15=#FAF6F0"
  ]
}'

apply_to_current_terminal_blocks() {
  local theme_json="$1"
  jq -e . >/dev/null <<<"$theme_json" || return 1

  while IFS= read -r session_id; do
    while IFS= read -r block_id; do
      if rex block call -s "$session_id" -b "$block_id" set_theme "$theme_json" >/dev/null; then
        printf 'Applied palette to %s in %s\n' "$block_id" "$session_id"
      else
        printf 'Could not apply palette to %s in %s\n' "$block_id" "$session_id" >&2
      fi
    done < <(
      rex block ls -s "$session_id" --json \
        | jq -r '.blocks[]? | select(.creator_name == "com.superlogical.terminal") | .block_id'
    )
  done < <(rex ls --json | jq -r '.sessions[]? | .session_id')
}

# Choose exactly one:
apply_to_current_terminal_blocks "$nightfox"
# apply_to_current_terminal_blocks "$warm_burnout_light"
```

4. Run it:

```bash
bash /tmp/apply-rex-ghostty-theme.sh
```

5. Check one terminal's normal and bright ANSI colors visually. A successful
   request does not prove that an owning client applied or retained the colors.
   `set_theme` is a write-only Rex method.

## Prompt for another agent

> Read `config/rex/ghostty-theme-import.md`. I want the persistent named Rex
> themes Nightfox and Warm Burnout Light, not just a temporary terminal palette.
> Find and verify Rex's current theme import procedure before making changes.
> Do not install packages or change app settings without my approval.
