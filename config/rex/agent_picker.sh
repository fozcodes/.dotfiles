#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="/Users/foz/.dotfiles/config/rex/agent_picker.sh"
REX_BIN="${REX_BIN:-$(command -v rex || true)}"
JQ_BIN="${JQ_BIN:-$(command -v jq || true)}"
FZF_BIN="${FZF_BIN:-$(command -v fzf || true)}"
for candidate in /opt/homebrew/bin/jq /usr/local/bin/jq /usr/bin/jq; do
  if [[ -z "$JQ_BIN" && -x "$candidate" ]]; then JQ_BIN="$candidate"; fi
done
for candidate in /opt/homebrew/bin/fzf /usr/local/bin/fzf; do
  if [[ -z "$FZF_BIN" && -x "$candidate" ]]; then FZF_BIN="$candidate"; fi
done
if [[ -z "$REX_BIN" && -x "/Users/foz/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex" ]]; then
  REX_BIN="/Users/foz/Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex"
fi
PICKER_SESSION="${REX_SESSION:-}"
PICKER_BLOCK="${REX_BLOCK:-}"
PICKER_CLIENT_ID=""
SELECTED_SESSION=""
SELECTED_BLOCK=""
SELECTED_WINDOW=""

fail() {
  printf 'pi-agent-picker: %s\n' "$1" >&2
  return 1
}

require_commands() {
  [[ -n "$REX_BIN" ]] || fail "rex CLI not found"
  [[ -n "$JQ_BIN" ]] || fail "jq not found"
  [[ -n "$FZF_BIN" ]] || fail "fzf not found"
}

rex_api() {
  "$REX_BIN" api call "$@"
}

clean_field() {
  local value="$1"
  value=${value//$'\t'/ }
  value=${value//$'\r'/ }
  value=${value//$'\n'/ }
  printf '%s' "$value"
}

status_rank() {
  case "$1" in
    blocked) printf '0' ;;
    error) printf '1' ;;
    done) printf '2' ;;
    idle) printf '3' ;;
    working) printf '4' ;;
    *) printf '5' ;;
  esac
}

status_style() {
  case "$1" in
    blocked) printf '\033[38;5;203m◆\033[0m' ;;
    error) printf '\033[38;5;203m×\033[0m' ;;
    done) printf '\033[38;5;114m✓\033[0m' ;;
    idle) printf '\033[38;5;110m·\033[0m' ;;
    working) printf '\033[38;5;222m●\033[0m' ;;
    *) printf '\033[38;5;245m?\033[0m' ;;
  esac
}

is_pi_process() {
  "$JQ_BIN" -e '
    [.foreground.argv0 // "", .foreground.script // "", .foreground.name // ""]
    | any(.[]; . == "pi" or test("(^|/)pi$"; "i"))
  ' >/dev/null
}

matching_status_record() {
  "$JQ_BIN" -c '
    def rank:
      if . == "blocked" then 0
      elif . == "error" then 1
      elif . == "done" then 2
      elif . == "idle" then 3
      elif . == "working" then 4
      else 5
      end;
    [.records[]?
      | select(((.effective_app // .app // "") | tostring | ascii_downcase) == "pi")]
    | sort_by(.state | rank)
    | .[0] // {}
  '
}

list_rows() {
  require_commands
  local sessions_json
  sessions_json="$("$REX_BIN" ls --json)" || fail "could not list sessions"

  while IFS=$'\t' read -r session_id session_label; do
    [[ -n "$session_id" ]] || continue
    local view_json
    view_json="$(rex_api -s "$session_id" session.view)" || continue

    while IFS=$'\t' read -r window_id window_label block_id; do
      [[ -n "$block_id" ]] || continue

      local process_json status_json status_record state status_message title cwd project
      process_json="$(rex_api -s "$session_id" block.method \
        "$("$JQ_BIN" -cn --arg block "$block_id" \
          '{block_id:$block,method:"process"}')" 2>/dev/null)" || continue
      status_json="$(rex_api -s "$session_id" block.method \
        "$("$JQ_BIN" -cn --arg block "$block_id" \
          '{block_id:$block,method:"program_status"}')" 2>/dev/null)" || status_json='{"records":[]}'

      status_record="$(printf '%s' "$status_json" | matching_status_record)"
      if [[ "$status_record" == '{}' ]] && ! printf '%s' "$process_json" | is_pi_process; then
        continue
      fi

      state="$(printf '%s' "$status_record" | "$JQ_BIN" -r '.state // "unknown"')"
      status_message="$(printf '%s' "$status_record" | "$JQ_BIN" -r '.msg // ""')"
      title="$(printf '%s' "$status_record" | "$JQ_BIN" -r '.title // ""')"
      cwd="$(printf '%s' "$process_json" | "$JQ_BIN" -r '.foreground.cwd // ""')"
      project="${cwd%/}"
      project="${project##*/}"
      [[ -n "$title" ]] || title="$project"
      [[ -n "$title" ]] || title="Pi"
      [[ -n "$session_label" ]] || session_label="Session"
      [[ -n "$window_label" ]] || window_label="Window"

      local marker display rank
      marker="$(status_style "$state")"
      rank="$(status_rank "$state")"
      display="$marker $state  $(clean_field "$title")  $(clean_field "$session_label") / $(clean_field "$window_label")"
      printf '%s\037%s\037%s\037%s\037%s\037%s\037%s\n' \
        "$rank" "$display" "$session_id" "$block_id" \
        "$(clean_field "$status_message")" "$(clean_field "$title")" "$window_id"
    done < <("$JQ_BIN" -r '
      .windows[]? as $window
      | $window.layers[]?.blocks[]?
      | select(.creator_name == "com.superlogical.terminal")
      | [$window.window_id // "", $window.label // "", .block_id // ""]
      | @tsv
    ' <<< "$view_json")
  done < <("$JQ_BIN" -r '.sessions[]? | [.session_id, .label // ""] | @tsv' <<< "$sessions_json") \
    | sort -t $'\037' -k1,1n -k2,2
}

preview_pane() {
  local session_id="$1"
  local block_id="$2"
  local status_message="$3"
  local format_args format_json blob_id total offset blob_args blob_json content

  if [[ -n "$status_message" ]]; then
    printf '\033[38;5;110m%s\033[0m\n\n' "$status_message"
  fi

  format_args="$("$JQ_BIN" -cn --arg block "$block_id" \
    '{block_id:$block,method:"format",args:{format:"text",trim:true,unwrap:true,max_bytes:4096}}')"
  format_json="$(rex_api -s "$session_id" block.method "$format_args" 2>/dev/null)" || {
    printf 'Terminal preview is unavailable.\n'
    return 0
  }

  blob_id="$("$JQ_BIN" -r '.id // empty' <<< "$format_json")"
  if [[ -n "$blob_id" ]]; then
    total="$("$JQ_BIN" -r '.total // 0' <<< "$format_json")"
    offset=$((total - 16384))
    (( offset < 0 )) && offset=0
    blob_args="$("$JQ_BIN" -cn --arg block "$block_id" \
      --argjson id "$blob_id" --argjson offset "$offset" \
      '{block_id:$block,id:$id,offset:$offset,max_bytes:16384}')"
    blob_json="$(rex_api -s "$session_id" com.superlogical.terminal.blob_read "$blob_args" 2>/dev/null)" || blob_json='{}'
    content="$("$JQ_BIN" -r '.data // ""' <<< "$blob_json")"
  else
    content="$("$JQ_BIN" -r '.content // ""' <<< "$format_json")"
  fi
  printf '%s\n' "$content" | tail -n 60
}

close_picker_layer() {
  [[ -n "$PICKER_SESSION" && -n "$PICKER_BLOCK" ]] || return 0
  local view_json layer_id args
  view_json="$(rex_api -s "$PICKER_SESSION" session.view 2>/dev/null)" || return 0
  layer_id="$("$JQ_BIN" -r --arg block "$PICKER_BLOCK" '
    [.windows[]?.layers[]?
      | select(any(.blocks[]?; .block_id == $block))
      | .layer_id][0] // empty
  ' <<< "$view_json")"
  [[ -n "$layer_id" ]] || return 0
  args="$("$JQ_BIN" -cn --arg layer "$layer_id" '{layer_id:$layer}')"
  rex_api -s "$PICKER_SESSION" session.close_layer "$args" >/dev/null 2>&1 || true
}

schedule_session_select() {
  local args
  args="$("$JQ_BIN" -cn \
    --arg script "$SCRIPT_PATH" \
    --arg rex "$REX_BIN" \
    --arg source_session "$PICKER_SESSION" \
    --arg picker_block "$PICKER_BLOCK" \
    --arg target_session "$SELECTED_SESSION" \
    --arg target_window "$SELECTED_WINDOW" \
    --arg client "$PICKER_CLIENT_ID" \
    '{script:$script,rex:$rex,source_session:$source_session,picker_block:$picker_block,target_session:$target_session,target_window:$target_window,client:$client}')"
  "$REX_BIN" do -e '
    local args = rex.args
    local child, err = rex.exec.start({
      "/bin/bash", args.script, "select_after_close", args.rex,
      args.source_session, args.picker_block, args.target_session,
      args.target_window, args.client,
    }, { detach = true, stdout = false, stderr = false })
    if not child then error(err, 0) end
  ' --args "$args" >/dev/null
}

focus_selected_pane() {
  local args
  args="$("$JQ_BIN" -cn --arg block "$SELECTED_BLOCK" '{block_id:$block}')"
  rex_api -s "$SELECTED_SESSION" session.focus_block "$args" >/dev/null
  schedule_session_select
}

select_session_after_close() {
  local rex_bin="$2"
  local source_session="$3"
  local picker_block="$4"
  local target_session="$5"
  local target_window="$6"
  local app_client="$7"
  local attempt view is_open

  REX_BIN="$rex_bin"
  require_commands
  for ((attempt = 0; attempt < 100; attempt++)); do
    view="$("$REX_BIN" api call -s "$source_session" session.view 2>/dev/null || true)"
    if [[ -n "$view" ]] && ! printf '%s' "$view" | "$JQ_BIN" -e --arg block "$picker_block" '
      any(.windows[]?.layers[]?.blocks[]?; .block_id == $block)
    ' >/dev/null 2>&1; then
      is_open=0
      break
    fi
    is_open=1
    sleep 0.1
  done
  [[ "${is_open:-1}" == 0 ]] || fail "picker did not close before session switch"
  if ! "$REX_BIN" -C "$app_client" do session.select \
    "session_id=$target_session" "window_id=$target_window" >/dev/null 2>&1; then
    return 1
  fi
}

run_picker() {
  require_commands
  [[ -n "$PICKER_SESSION" && -n "$PICKER_BLOCK" && -n "$PICKER_CLIENT_ID" ]] || fail "Rex session, pane, or client ID is missing"
  local rows selection preview_command
  rows="$(list_rows)"
  if [[ -z "$rows" ]]; then
    printf 'No Pi agents found in any Rex session.\n'
    sleep 1
    return 0
  fi

  printf -v preview_command 'bash %q preview {2} {3} {4}' "$SCRIPT_PATH"
  if ! selection="$(printf '%s\n' "$rows" | cut -d $'\037' -f2- | FZF_DEFAULT_OPTS= FZF_DEFAULT_OPTS_FILE= "$FZF_BIN" \
    --ansi \
    --style=full \
    --layout=reverse \
    --border=rounded \
    --border-label=' Pi agents ' \
    --border-label-pos=3 \
    --delimiter=$'\037' \
    --with-nth=1 \
    --no-multi \
    --cycle \
    --tiebreak=begin \
    --prompt=' pi  › ' \
    --pointer='▌' \
    --marker='✓' \
    --info=inline-right \
    --header='↑/↓ move  ·  type to filter  ·  enter focus  ·  esc close' \
    --preview="$preview_command" \
    --preview-window='right:58%:border-left:rounded:wrap' \
    --preview-label=' Status + terminal ' \
    --preview-label-pos=3 \
    --color='fg:#d8dee9,bg:#2e3440,hl:#88c0d0,fg+:#eceff4,bg+:#3b4252,hl+:#88c0d0,prompt:#88c0d0,pointer:#a3be8c,marker:#ebcb8b,spinner:#b48ead,header:#81a1c1,border:#4c566a,label:#88c0d0,info:#81a1c1')"; then
    return 0
  fi

  [[ -n "$selection" ]] || return 0
  IFS=$'\037' read -r _ SELECTED_SESSION SELECTED_BLOCK _ _ SELECTED_WINDOW <<< "$selection"
  [[ -n "$SELECTED_SESSION" && -n "$SELECTED_BLOCK" && -n "$SELECTED_WINDOW" ]] || fail "selected row has no target pane or window"
  focus_selected_pane
}

mode="${1:-pick}"
case "$mode" in
  list)
    list_rows
    ;;
  preview)
    require_commands
    preview_pane "${2:?session ID required}" "${3:?pane ID required}" "${4:-}"
    ;;
  pick)
    PICKER_CLIENT_ID="${2:-}"
    [[ -n "$PICKER_CLIENT_ID" ]] || fail "Rex app client ID is missing"
    trap close_picker_layer EXIT
    run_picker
    ;;
  select_after_close)
    select_session_after_close "$@"
    ;;
  *)
    fail "unknown mode: $mode"
    ;;
esac
