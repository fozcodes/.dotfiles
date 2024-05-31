local lspconfig = require("lspconfig")

local M = {}
M.setup = function(on_attach, capabilities)
    lspconfig.tsserver.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)

            client.server_capabilities.document_formatting = false
            client.server_capabilities.document_range_formatting = false

            on_attach(client, bufnr)
        end,
        filetypes = {"typescript", "typescriptreact", "typescript.tsx"}
    })
end

return M
