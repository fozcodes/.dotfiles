local nvim_lsp = require("lspconfig")

local M = {}
M.setup = function(on_attach)

    nvim_lsp.vuels.setup {
        on_attach = function(client, bufnr)
            client.resolved_capabilities.document_formatting = true
            vim.cmd [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()]]
            on_attach(client, bufnr)
        end;
        filetypes = { "vue" },
        settings = {
            vetur = {
                completion = {
                    autoImport = false,
                    tagCasing = "kebab",
                    useScaffoldSnippets = false
                },
                format = {
                    defaultFormatter = {
                        js = "prettier",
                        ts = "prettier",
                        html = "prettier"
                    },
                    scriptInitialIndent = false,
                    styleInitialIndent = false,
                    useTabs = false,
                },
                useWorkspaceDependencies = true,
                validation = {
                    script = true,
                    style = true,
                    template = true
                }
            }
        }
    }

end

return M
