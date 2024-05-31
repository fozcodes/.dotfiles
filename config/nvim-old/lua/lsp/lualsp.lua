local nvim_lsp = require("lspconfig")

-- https://www.chrisatmachine.com/Neovim/28-neovim-lua-development/
-- https://github.com/sumneko/lua-language-server/wiki/Build-and-Run-(Standalone)
USER = vim.fn.expand('$USER')

local sumneko_root_path = ""
local sumneko_binary = ""

if vim.fn.has("mac") == 1 then
    sumneko_root_path = "/Users/" .. USER .. "/.lang-servers/lua-language-server"
    sumneko_binary = "/Users/" .. USER
                         .. "/.lang-servers/lua-language-server/bin/lua-language-server"
elseif vim.fn.has("unix") == 1 then
    sumneko_root_path = "/home/" .. USER .. "/.lang-servers/lua-language-server"
    sumneko_binary = "/home/" .. USER
                         .. "/.lang-servers/lua-language-server/bin/Linux/lua-language-server"
else
    print("Unsupported system for sumneko")
end

local M = {}
M.setup = function(on_attach, capabilities)
    nvim_lsp.lua_ls.setup({
        cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
        capabilities = capabilities,
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            on_attach(client, bufnr)
        end,
        settings = {
            Lua = {
                format = {enable = false},
                runtime = {
                    -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT',
                    -- Setup your lua path
                    path = vim.split(package.path, ';')
                },
                diagnostics = {
                    -- Get the language server to recognize the `vim` global
                    globals = {'vim'}
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = {
                        [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                        [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
                    }
                }
            }
        }
    })
end

return M
