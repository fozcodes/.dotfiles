-- Copy-mode viewer. Loaded via `dofile` from a bare Neovim launched by
-- copy_mode.lua (no user config, plugins, shada or swapfile). Owns cleanup:
-- any exit deletes the capture directory and best-effort refocuses the pane
-- the user was reading, without stealing focus from a pane they moved to.
local directory = vim.g.copy_mode_capture_dir
local metadata = {}

local function read_binary(path)
  local file = assert(io.open(path, "rb"))
  local data = file:read("*a")
  file:close()
  return data or ""
end

-- Validate before touching anything: the path must be a copy-mode snapshot
-- directory that this user owns, so a stale or hostile glyph/path never loads.
local stat = directory and vim.uv.fs_lstat(directory) or nil
assert(
  directory and directory:match("/rex%-copy%-mode%-%w+$") and stat and stat.type == "directory"
    and stat.uid == vim.uv.getuid(),
  "not an owned rex copy-mode temporary directory"
)

local function run_cli(argv)
  local result = vim.system(argv, { text = true, timeout = 2000 }):wait()
  if result.code ~= 0 then
    error("rex CLI failed: " .. argv[1], 0)
  end
  return result.stdout
end

-- Refocus the source pane, but only while this viewer is still the focused
-- block of the source window; if the user moved to a pane or tab already,
-- leave their focus where they put it.
local function restore_focus()
  if not metadata.session or not metadata.source_block then
    return false
  end
  local own_block = tonumber(vim.env.REX_BLOCK)
  if not own_block then
    own_block = vim.json.decode(run_cli({ metadata.rex_cli, "whoami", "--json" })).block_id
  end
  if not own_block then
    return false
  end
  local current = vim.json.decode(run_cli({ metadata.rex_cli, "session", "inspect", metadata.session, "--json" }))
  if current.active_window_id ~= metadata.source_window then
    return false
  end
  for _, window in ipairs(current.windows or {}) do
    if window.window_id == metadata.source_window and window.focused_block_id == own_block then
      run_cli({ metadata.rex_cli, "focus", "-s", metadata.session, metadata.source_block })
      if metadata.source_zoomed then
        run_cli({ metadata.rex_cli, "zoom", "-s", metadata.session, metadata.source_block, "--on" })
      end
      return true
    end
  end
  return false
end

-- Tiny confirmation after a copy: a label-only floating pane shown briefly at
-- the bottom of the source window. Best effort; never blocks exit.
local function show_copied_toast()
  if not metadata.session or not metadata.source_window then
    return
  end
  local text = "Copied to clipboard"
  local bounds = metadata.source_bounds or { 0, 0, 1, 1 }
  local width = math.min(0.9, (#text + 8) * bounds[3] / vim.o.columns)
  local height = math.min(0.12, 1.6 * bounds[4] / vim.o.lines)
  run_cli({
    metadata.rex_cli,
    "api", "call",
    "-s", metadata.session,
    "session.new_layer",
    vim.json.encode({
      session_id = metadata.session,
      window_id = metadata.source_window,
      bounds = { (1 - width) / 2, 1 - height, width, height },
      focus = false,
      layout = { block = {
        flavor = "com.superlogical.terminal.shell",
        label = text,
        options = {
          shell = "none",
          command = { "sleep", tostring(metadata.toast_seconds or 0) },
          size = { columns = #text + 8, rows = 1 },
          exit = { on_completion = true, quick_exit_threshold_ms = 0 },
        },
      } },
    }),
  })
end

-- Type the pasted selection straight into the source terminal pane. `rex
-- send` takes the text as one argv element (no shell), so newlines inside the
-- selection are sent literally.
local function paste_selection_to_pane()
  if not (metadata.paste_to_pane and metadata.session and metadata.source_block) then
    return
  end
  local selection = vim.fn.getreg("+") or ""
  if #selection > 0 then
    -- Strip one trailing newline: the pane still has its own prompt.
    selection = selection:gsub("\n$", "")
    if #selection > 0 then
      run_cli({
        metadata.rex_cli,
        "send",
        "-s", metadata.session,
        "-b", tostring(metadata.source_block),
        selection,
      })
    end
  end
end

-- Shared exit hook for the selection mappings. They yank to the '+' register
-- with normal-mode keystrokes BEFORE calling this, so the selection is already
-- in the register here: paste types it into the source pane, copy marks the
-- toast flag. The mapping supplies the closing <Cmd>qa!<CR> itself.
local function finish(action)
  if action == "paste" then
    pcall(paste_selection_to_pane)
  else
    vim.g.copy_mode_copied = true
  end
end
_G.copy_mode_finish = finish

-- Cleanup runs on every exit, including failure paths below, and must not
-- depend on the server being alive or a payload lint; each step is guarded.
vim.api.nvim_create_autocmd("VimLeavePre", {
  once = true,
  callback = function()
    -- Ignore failures: a closed pane or server must not block cleanup.
    local refocus_ok, refocused = pcall(restore_focus)
    if refocus_ok and refocused and vim.g.copy_mode_copied and (metadata.toast_seconds or 0) > 0 then
      pcall(show_copied_toast)
    end
    vim.fn.delete(directory, "rf")
  end,
})

local function start_viewer()
  metadata = vim.json.decode(read_binary(directory .. "/meta.json"))
  assert(type(metadata) == "table", "copy-mode metadata is not a JSON object")

  vim.opt.termguicolors = true
  vim.opt.clipboard = "unnamedplus"
  vim.opt.title = true
  vim.opt.titlelen = 0
  vim.opt.titlestring = metadata.title:gsub("%%", "%%%%")
  -- No chrome: every terminal row belongs to the snapshot.
  vim.opt.laststatus = 0
  vim.opt.cmdheight = 0
  vim.opt.showtabline = 0
  vim.opt.showmode = false
  vim.opt.showcmd = false
  vim.opt.ruler = false
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = "no"
  vim.opt.foldcolumn = "0"
  vim.opt.modeline = false
  vim.opt.swapfile = false
  vim.opt.shadafile = "NONE"

  -- A terminal buffer represents soft-wrapped screen rows as separate buffer
  -- lines. Copying a visual selection from it therefore inserts line breaks
  -- that the source program never wrote. Load Rex's already-unwrapped text in
  -- a normal no-wrap buffer so each buffer line stays a logical output line.
  vim.cmd("edit " .. vim.fn.fnameescape(directory .. "/capture.txt"))
  local buffer = vim.api.nvim_get_current_buf()
  vim.bo[buffer].bufhidden = "wipe"
  vim.bo[buffer].filetype = "copy-mode"
  vim.bo[buffer].modifiable = false
  vim.bo[buffer].readonly = true
  vim.wo.wrap = false
  vim.wo.linebreak = false

  -- Visual mode: selection actions. y and <CR> copy to the system clipboard
  -- and close; p (when enabled) also types the selection into the source pane.
  -- The rhs runs " +y as keystrokes so the visual selection is what gets yanked.
  local selection_actions = { y = "copy", ["<CR>"] = "copy" }
  if metadata.paste_to_pane then
    selection_actions.p = "paste"
  end
  for key, action in pairs(selection_actions) do
    vim.keymap.set("x", key, '"+y<Cmd>lua _G.copy_mode_finish("' .. action .. '")<CR><Cmd>qa!<CR>', {
      buffer = buffer,
      silent = true,
      nowait = true,
      desc = "selection: copy/paste and close",
    })
  end
  -- Plain y in normal mode: yank the whole line, not operator-pending.
  vim.keymap.set("n", "y", '"+yy<Cmd>lua _G.copy_mode_finish("copy")<CR><Cmd>qa!<CR>', {
    buffer = buffer,
    silent = true,
    desc = "Yank line and close copy-mode",
  })

  -- q exits from normal or visual mode. Esc also closes in normal mode.
  vim.keymap.set({ "n", "v" }, "q", "<Cmd>qa!<CR>", { buffer = buffer, silent = true })
  vim.keymap.set({ "n", "v" }, "<Esc>", "<Cmd>qa!<CR>", { buffer = buffer, silent = true })

  vim.api.nvim_win_set_cursor(0, { math.max(1, vim.fn.prevnonblank("$")), 0 })
  vim.cmd("normal! zb")
end

local ok, err = pcall(start_viewer)
if not ok then
  -- Fail closed: never render a half-initialized viewer or print payloads.
  io.stderr:write("copy-mode: " .. tostring(err), "\n")
  vim.cmd("cquit 1")
end
