local lspconfig = require('lspconfig')

local M = {}
M.setup = function(on_attach, capabilities)
    lspconfig.yamlls.setup {
        settings = {
            yaml = {
                schemas = {
                    ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "**/workflow/*",
                    ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*"
                }
            }
        }
    }
end

return M

