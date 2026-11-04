-- Hand-written Rex copy-mode, replacing the vendored CJNE/rex-copy-mode
-- (https://github.com/CJNE/rex-copy-mode, MIT). Same concept: open the focused
-- pane's scrollback as a styled snapshot in a disposable Neovim overlay.
-- The Neovim entry point lives beside this file as copy_mode_view.lua; shared
-- pure helpers are in copy_mode_common.lua.
local root = assert(debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)"), "copy_mode.lua must load from a file")
local common = dofile(root .. "copy_mode_common.lua")

local M = {}

local MAX_CAPTURE_BYTES = 128 * 1024 * 1024
local CHUNK_BYTES = 983040 -- just under 1 MiB, without counting Lua string overhead

local function checked(result, err)
  if not result then
    error(err or "Rex operation failed", 0)
  end
  return result
end

-- Run one helper with a timeout, treating every failure as fatal with context.
local function exec(argv)
  local result, err = rex.exec(argv, { timeout = 5 })
  if not result or not result.ok then
    error("copy-mode helper failed: " .. argv[1] .. (err and (": " .. err) or ""), 0)
  end
  return result
end

-- Resolve an executable name or path once, in Rex's command environment, so
-- the launched viewer does not depend on Rex's terminal launcher PATH.
local function executable(name)
  local result = exec({ "which", name })
  local resolved = result.stdout:match("[^\r\n]+")
  if not resolved or #resolved == 0 then
    error("cannot locate " .. name .. "; pass an absolute path", 0)
  end
  return resolved
end

local function terminal_call(ctx, method, args)
  return checked(rex.block.call("com.superlogical.terminal", method, {
    session_id = ctx.session_id,
    block_id = ctx.block_id,
    args = args or {},
  }))
end

-- Stream the pane's scrollback through the terminal API into `path`.
local function write_capture(ctx, path)
  local file = assert(io.open(path, "wb"))
  local ok, err = pcall(function()
    local bytes = 0
    local part = terminal_call(ctx, "format", {
      format = "vt",
      trim = true,
      unwrap = true,
      max_bytes = CHUNK_BYTES,
    })
    while true do
      local chunk = part.content or part.data or ""
      file:write(chunk)
      bytes = bytes + #chunk
      if bytes > MAX_CAPTURE_BYTES then
        error("pane capture exceeds 128 MiB", 0)
      end
      local finished = part.eof == true
        or not part.data and type(part.id) ~= "string"
        or (part.total and bytes >= part.total)
      local more = not finished and type(part.id) == "string"
      if not more then
        if #chunk == 0 then
          error("pane capture is empty", 0)
        end
        if chunk:sub(-1) ~= "\n" then
          file:write("\n")
        end
        break
      end
      part = terminal_call(ctx, "blob_read", {
        id = part.id,
        offset = bytes,
        max_bytes = CHUNK_BYTES,
      })
      if not part or not part.data or #part.data == 0 then
        error("pane capture stream ended early", 0)
      end
    end
  end)
  file:close()
  if not ok then
    error(err, 0)
  end
end

local function delete_snapshot(directory)
  os.remove(directory .. "/capture.vt")
  os.remove(directory .. "/meta.json")
  pcall(rex.exec, { "rmdir", directory }, { timeout = 2 })
end

function M.setup(user)
  local options = {
    key = "ctrl+a>enter",
    nvim = "nvim",
    rex = "rex",
    toast_seconds = 1.2,
    paste_to_pane = false,
  }
  for name, value in pairs(user or {}) do
    assert(options[name] ~= nil, "unknown copy-mode option: " .. tostring(name))
    options[name] = value
  end
  for _, name in ipairs({ "nvim", "rex" }) do
    assert(type(options[name]) == "string" and #options[name] > 0, name .. " must be a path or executable name")
  end
  assert(
    options.key == false or (type(options.key) == "string" and #options.key > 0),
    "key must be a Rex shortcut or false"
  )
  assert(
    type(options.toast_seconds) == "number" and options.toast_seconds >= 0 and options.toast_seconds ~= math.huge,
    "toast_seconds must be a finite nonnegative number"
  )
  assert(type(options.paste_to_pane) == "boolean", "paste_to_pane must be a boolean")

  options.nvim = executable(options.nvim)
  options.rex = executable(options.rex)

  rex.action({
    name = "copy_mode",
    title = "Copy Mode",
    description = "Vim-style scrollback: search, select, yank, optional paste; :q cancels",
    category = "Pane",
    keywords = "copy mode scrollback vim nvim yank capture",
    run = function(ctx, args)
      if not ctx.session_id or not ctx.block_id then
        error("copy-mode needs a focused terminal pane", 0)
      end
      local source = checked(rex.session.describe_block({
        session_id = ctx.session_id,
        block_id = ctx.block_id,
      }))
      if source.block.creator_name ~= "com.superlogical.terminal" then
        error("copy-mode needs a terminal pane", 0)
      end
      local window_id = source.block.window_id
      if not window_id then
        error("source pane is not inside a window", 0)
      end
      local view = checked(rex.session.view({ session_id = ctx.session_id }))
      local bounds, zoomed = common.pane_bounds(view, window_id, ctx.block_id)

      local temporary_root = (os.getenv("TMPDIR") or "/tmp"):gsub("/+$", "")
      local directory = exec({ "mktemp", "-d", temporary_root .. "/rex-copy-mode-XXXXXXXXXX" }).stdout:gsub("%s+$", "")
      local opened = false
      local ok, result = pcall(function()
        write_capture(ctx, directory .. "/capture.vt")
        local metadata = {
          title = common.title(terminal_call(ctx, "title").title or "", source.block.label),
          session = ctx.session_id,
          source_block = ctx.block_id,
          source_window = window_id,
          source_zoomed = zoomed,
          source_bounds = bounds,
          rex_cli = options.rex,
          toast_seconds = options.toast_seconds,
          paste_to_pane = options.paste_to_pane,
        }
        local file = assert(io.open(directory .. "/meta.json", "wb"))
        assert(file:write(checked(rex.json.encode(metadata))))
        file:close()
        -- Parent is already 0700; tighten both files to 0600 before launch.
        exec({ "chmod", "600", directory .. "/capture.vt", directory .. "/meta.json" })
        local layer = checked(rex.session.new_layer({
          session_id = ctx.session_id,
          window_id = window_id,
          bounds = bounds,
          focus = true,
          layout = rex.layout.block({
            flavor = "com.superlogical.terminal.shell",
            label = metadata.title,
            options = {
              shell = "none",
              command = {
                options.nvim,
                "-u", "NONE",
                "-i", "NONE",
                "-n",
                "--cmd", "set nomodeline",
                "--cmd", "lua vim.g.copy_mode_capture_dir = " .. string.format("%q", directory),
                "-c", "lua dofile(" .. string.format("%q", root .. "copy_mode_view.lua") .. ")",
              },
              exit = { on_completion = true, quick_exit_threshold_ms = 0 },
            },
          }),
        }))
        opened = true -- Neovim now owns cleanup, including startup failure.
        if ctx.client_id and (ctx.origin == "key" or ctx.origin == "palette") then
          rex.client.queue("session.select", {
            session_id = ctx.session_id,
            window_id = window_id,
          })
        end
        return layer
      end)
      if not opened then
        delete_snapshot(directory)
      end
      if not ok then
        error(result, 0)
      end
      return result
    end,
  })

  if options.key then
    rex.bind(options.key, "copy_mode")
  end
  return M
end

return M
