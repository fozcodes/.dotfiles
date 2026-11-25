local function run_rex_focus(direction)
  -- Current Rex builds expose the block environment through REX_BLOCK and
  -- scope CLI calls to that block's session automatically; older builds
  -- exposed REX_SESSION and needed --session. Accept either.
  local session_id = vim.env.REX_SESSION
  local block_id = vim.env.REX_BLOCK
  local has_session = session_id ~= nil and session_id ~= ""
  local has_block = block_id ~= nil and block_id ~= ""
  if not has_session and not has_block then
    vim.notify("Rex session or block ID is unavailable", vim.log.levels.ERROR)
    return
  end

  local executable = vim.env.REX_BIN_PATH
  if not executable or executable == "" then
    executable = "rex"
  end

  local command = { executable }
  local server = vim.env.REX_SERVER
  if server and server ~= "" then
    command[#command + 1] = "-S"
    command[#command + 1] = server
  end
  command[#command + 1] = "focus"
  command[#command + 1] = direction
  if has_session then
    command[#command + 1] = "--session"
    command[#command + 1] = session_id
  end

  local output = vim.fn.system(command)
  if vim.v.shell_error ~= 0 then
    vim.notify("Rex pane focus failed: " .. output, vim.log.levels.ERROR)
  end
end

local function navigate(wincmd, direction)
  local previous_window = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= previous_window then
    return
  end
  run_rex_focus(direction)
end

vim.keymap.set("n", "<C-h>", function()
  navigate("h", "left")
end, { silent = true, noremap = true, desc = "Navigate left across Neovim and Rex panes" })

vim.keymap.set("n", "<C-j>", function()
  navigate("j", "down")
end, { silent = true, noremap = true, desc = "Navigate down across Neovim and Rex panes" })

vim.keymap.set("n", "<C-k>", function()
  navigate("k", "up")
end, { silent = true, noremap = true, desc = "Navigate up across Neovim and Rex panes" })

vim.keymap.set("n", "<C-l>", function()
  navigate("l", "right")
end, { silent = true, noremap = true, desc = "Navigate right across Neovim and Rex panes" })
