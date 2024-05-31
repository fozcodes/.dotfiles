local nvim_lsp = require("lspconfig")

local M = {}
M.setup = function(on_attach, capabilities)

    nvim_lsp.gopls.setup {
        cmd = {'gopls'},
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = true
            vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]
            on_attach(client, bufnr)
        end,
        capabilities = capabilities,
        settings = {
            gopls = {
                experimentalPostfixCompletions = true,
                analyses = {unusedparams = true, shadow = true},
                staticcheck = true
            }
        },
        filetypes = {"go"}
    }

end

return M

