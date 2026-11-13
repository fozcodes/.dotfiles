-- Run from the repository root: nvim --headless -u NONE -l config/nvim/tests/markdown_view.lua
vim.opt.runtimepath:append(vim.fn.stdpath "data" .. "/lazy/conform.nvim")
local conform = require "conform"
conform.setup {
  formatters = {
    markdown_unwrap = {
      inherit = "prettierd",
      append_args = { "--prose-wrap=never" },
    },
  },
}

local source = table.concat(vim.fn.readfile "config/nvim/init.lua", "\n")
local command = assert(source:match '(vim%.api%.nvim_create_user_command%(%"ToggleMarkdownView%".-\nend, { desc = %"Toggle Markdown readable view%" }%))')
assert(loadstring(command))()

vim.cmd "enew"
vim.api.nvim_buf_set_name(0, vim.fn.tempname() .. ".md")
vim.bo.filetype = "markdown"
vim.bo.textwidth = 80
vim.bo.wrapmargin = 3
vim.wo.wrap = false
vim.wo.linebreak = false
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "First line", "second line.", "", "- item", "  continuation" })
local columns = vim.o.columns

vim.cmd "ToggleMarkdownView"
assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "First line second line.")
assert(vim.bo.textwidth == 0 and vim.bo.wrapmargin == 0 and vim.wo.wrap and vim.wo.linebreak)
assert(vim.b.disable_autoformat == true and vim.o.columns == columns)
local markdown_buffer = vim.api.nvim_get_current_buf()
vim.cmd "enew"
assert(vim.b.disable_autoformat == nil and vim.b.markdown_view_previous == nil)
vim.api.nvim_set_current_buf(markdown_buffer)

vim.cmd "ToggleMarkdownView"
assert(vim.bo.textwidth == 80 and vim.bo.wrapmargin == 3 and not vim.wo.wrap and not vim.wo.linebreak)
assert(vim.b.disable_autoformat == nil)

vim.b.disable_autoformat = true
vim.cmd "ToggleMarkdownView"
vim.cmd "ToggleMarkdownView"
assert(vim.b.disable_autoformat == true)

local format = conform.format
local notify = vim.notify
local notification
vim.notify = function(message, level)
  notification = { message = message, level = level }
end
conform.format = function(_, callback)
  callback "formatter failed"
end
vim.cmd "ToggleMarkdownView"
assert(vim.b.markdown_view_previous == nil and vim.bo.textwidth == 80)
assert(notification and notification.level == vim.log.levels.ERROR)
conform.format = format
vim.notify = notify

print "Markdown view toggle tests passed"
vim.cmd "qa!"
