local u = require("utils")
local tsserver = require("lsp.tsserver")
local elixir = require("lsp.elixirls")
local efm = require("lsp.efm")
local pyright = require("lsp.pyright")
-- local pylsp = require("lsp.pylspserver")
local vue = require("lsp.vue")
local lua = require("lsp.lualsp")
local golang = require("lsp.golang")
local yaml = require("lsp.yaml")

-- https://neovim.io/doc/user/api.html#nvim_open_win()
local popup_opts = {border = "rounded", focusable = false, margin = {10, 10, 10, 10}}

_G.global.lsp = {popup_opts = popup_opts}

-- Uncomment the prints and start nvim to find the goddam LSP logfile again. Cause it ain't where you think!
-- vim.g.lua_lsp_log_file = os.getenv("HOME") .. "/.cache/nvim/lsp.log"
-- print("THIS IS THE LOG PATH")
-- print(vim.lsp.get_log_path())
-- vim.lsp.set_log_level('debug')

local virtual_text_prefix = function(client_name)
    if client_name == "efm" then
        return string.gsub("● $name: ", "%$(%w+)", {name = client_name})
    else
        return string.gsub("● $name: ", "%$(%w+)", {name = client_name})
    end
end

local M = {}
M.setup = function()
    local on_attach = function(client, bufnr)
        -- if vim.fn.has 'nvim-0.5.1' == 1 then
        -- require('vim.lsp.log').set_format_func(vim.inspect)
        -- end

        -- commands
        u.lua_command("LspFormatting", "vim.lsp.buf.formatting()")
        u.lua_command("LspHover", "vim.lsp.buf.hover()")
        u.lua_command("LspRename", "vim.lsp.buf.rename()")
        u.lua_command("LspDef", "vim.lsp.buf.definition()")
        u.lua_command("LspDecl", "vim.lsp.buf.declaration()")
        u.lua_command("LspDiagPrev", "vim.lsp.prev_diagnostic()")
        u.lua_command("LspDiagNext", "vim.lsp.next_diagnostic()")
        u.lua_command("LspDiagLine", "vim.diagnostic.open_float(global.lsp.popup_opts)")
        u.lua_command("LspSignatureHelp", "vim.lsp.buf.signature_help()")

        u.buf_augroup("LspAutocommands", "CursorHold", "LspDiagLine")

        local opts = {noremap = true, silent = true}
        -- bindings
        u.buf_map("n", "gd", ":LspDef<CR>", opts, bufnr)
        u.buf_map("n", "gD", ":LspDecl<CR>", opts, bufnr)
        u.buf_map("n", "gi", ":LspRename<CR>", nil, bufnr)
        u.buf_map("n", "K", ":LspHover<CR>", nil, bufnr)
        u.buf_map("n", "[a", ":LspDiagPrev<CR>", nil, bufnr)
        u.buf_map("n", "]a", ":LspDiagNext<CR>", nil, bufnr)
        u.buf_map("i", "<C-x><C-x>", "<cmd> LspSignatureHelp<CR>", nil, bufnr)

        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            border = "rounded",
            margin = {10, 10, 10, 10}
        })
        vim.lsp.handlers["textDocument/signatureHelp"] =
            vim.lsp.with(vim.lsp.handlers.signature_help, {border = "rounded"})
        -- Automatically update diagnostics ... from
        -- https://github.com/folke/dot/blob/master/config/nvim/lua/config/lsp/diagnostics.lua
        vim.lsp.handlers["textDocument/publishDiagnostics"] =
            vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    source = true,
                    spacing = 4
                    -- prefix = "● "
                },
                float = {source = true},
                severity_sort = true
            })

        local signs = {
            Error = "✖ ",
            Warning = " ",
            Warn = " ",
            Hint = " ",
            Information = " "
        }

        for type, icon in pairs(signs) do
            local hl = "DiagnosticSign" .. type
            vim.fn.sign_define(hl, {text = icon, texthl = hl, numhl = ""})
        end
    end

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {'documentation', 'detail', 'additionalTextEdits'}
    }

    local with_cmp_capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    tsserver.setup(on_attach, with_cmp_capabilities)
    elixir.setup(on_attach, with_cmp_capabilities)
    efm.setup(on_attach)
    pyright.setup(on_attach, with_cmp_capabilities)
    -- pylsp.setup(on_attach)
    vue.setup(on_attach, with_cmp_capabilities)
    lua.setup(on_attach, with_cmp_capabilities)
    golang.setup(on_attach, with_cmp_capabilities)
    yaml.setup(on_attach, with_cmp_capabilities)
end

return M

