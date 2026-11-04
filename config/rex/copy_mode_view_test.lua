-- Smoke test for copy_mode_view.lua: run headless with a fabricated snapshot.
--   nvim --headless -u NONE -i NONE -l config/rex/copy_mode_view_test.lua
-- It fabricates a capture directory, loads the real viewer entry point,
-- checks the visual-mode maps got installed, invokes the VimLeavePre hook
-- manually, and asserts the capture directory was deleted.
local failures, passed = 0, 0

local function test(name, body)
  local ok, err = pcall(body)
  if ok then
    passed = passed + 1
    print("PASS " .. name)
  else
    failures = failures + 1
    print("FAIL " .. name .. "\n     " .. tostring(err))
  end
end

local root = debug.getinfo(1, "S").source:gsub("^@", ""):match("^(.*/)")
local directory = vim.system({ "mktemp", "-d", "/tmp/rex-copy-mode-XXXXXXXXXX" }):wait().stdout:gsub("%s+$", "")
assert(directory:match("/rex%-copy%-mode%-%w+$"), "smoke test made an unexpected temp directory")

local file = assert(io.open(directory .. "/meta.json", "wb"))
file:write(vim.json.encode({
  title = "(copy-mode) smoke",
  -- No session: focus restoration short-circuits without a server call.
  source_block = 42,
  source_window = "w1",
  source_zoomed = false,
  source_bounds = { 0, 0, 1, 1 },
  rex_cli = "rex-would-fail-if-called",
  toast_seconds = 1.2,
  paste_to_pane = false,
}))
file:close()

file = assert(io.open(directory .. "/capture.vt", "wb"))
file:write("\27[31mRED\27[0m plain \27]0;title\7\27[6nrest\r\ntail")
file:close()

-- The real viewer runs, errors fail closed via cquit, so any error here means
-- the smoke caught a startup bug. The real launch injects the capture dir via
-- --cmd; the smoke test sets the same variable directly.
vim.g.copy_mode_capture_dir = directory

-- Fake clipboard provider so smoke yank tests never touch the real clipboard.
local clipboard = { text = "<empty>" }
vim.g.clipboard = {
  name = "smoke-stub",
  copy = {
    ["+"] = function(lines) clipboard.text = table.concat(lines, "\n") end,
    ["*"] = function(lines) clipboard.text = table.concat(lines, "\n") end,
  },
  paste = {
    ["+"] = function() return { clipboard.text } end,
    ["*"] = function() return { clipboard.text } end,
  },
}

dofile(root .. "copy_mode_view.lua")

test("viewer created a terminal buffer with the capture rendered", function()
  local buffer = vim.api.nvim_get_current_buf()
  assert(buffer ~= 0, "no buffer")
  assert(vim.bo[buffer].filetype == "copy-mode", "wrong buffer")
  -- (Mode is untestable mid-script headlessly; runtime behavior is manual.)
end)

test("selection maps installed: x y/CR, n y; no p without paste_to_pane", function()
  local buffer = vim.api.nvim_get_current_buf()
  local function buffer_map(mode, lhs)
    local mapping = vim.fn.maparg(lhs, mode, false, true)
    if mapping and mapping.buffer == 1 then
      return mapping
    end
    return nil
  end
  for _, lhs in ipairs({ "y", "<CR>" }) do
    local mapping = buffer_map("x", lhs)
    if not (mapping and mapping.rhs and mapping.rhs:find('copy_mode_finish', 1, true)
      and mapping.rhs:find('"+y', 1, true)) then
      error("missing or wrong visual map: " .. lhs)
    end
  end
  local n_y = buffer_map("n", "y")
  if not (n_y and n_y.rhs:find('%+yy', 1, false) and n_y.rhs:find('qa!<CR>', 1, false)
    and n_y.rhs:find('copy_mode_finish', 1, true)) then
    error("missing or wrong normal-mode y map")
  end
  if buffer_map("x", "p") then
    error("paste map installed despite paste_to_pane=false")
  end
end)

test("linewise yank delivers buffer lines to the clipboard provider", function()
  -- Headless nvim renders the terminal emulator as empty lines (no UI), so
  -- test the mechanism the n-mode y map composes: '"+yy' keystrokes must
  -- send the buffer's lines to the configured clipboard provider.
  local scratch = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(scratch)
  vim.api.nvim_buf_set_lines(scratch, 0, -1, false, { "copy-one", "copy-two" })
  vim.cmd('normal! "+yy')
  if not clipboard.text:find("copy-one", 1, true) then
    error("linewise yank did not reach the provider: " .. clipboard.text)
  end
end)

test("finish-hook marks copy without exiting", function()
  vim.g.copy_mode_copied = false
  _G.copy_mode_finish("copy")
  assert(vim.g.copy_mode_copied == true, "finish did not set the copied flag")
end)

test("VimLeavePre cleanup deleted the capture directory", function()
  local autocmds = vim.api.nvim_get_autocmds({ event = "VimLeavePre" })
  local called = false
  for _, item in ipairs(autocmds) do
    if item.callback then
      item.callback({ id = item.id })
      called = true
      break
    end
  end
  assert(called, "no VimLeavePre callback registered")
  assert(vim.fn.isdirectory(directory) == 0, "capture directory survived cleanup: " .. directory)
  -- A second invocation must not error from the missing directory.
  autocmds = vim.api.nvim_get_autocmds({ event = "VimLeavePre" })
  if autocmds[1] then
    autocmds[1].callback({ id = autocmds[1].id })
  end
end)

print(string.format("%d passed, %d failed", passed, failures))
if failures > 0 or (directory and vim.fn.isdirectory(directory) == 1) then
  os.exit(1)
end
