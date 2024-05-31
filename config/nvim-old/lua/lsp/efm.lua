local nvim_lsp = require("lspconfig")
local util = require('lspconfig/util')

local path = util.path

-- efm-langserver language modules--

-- Filetypes supported --
local efm_filetypes = {
    "elixir", "typescript", "typescriptreact", "javascript", "javascript.jsx", "jsx", "helm.yaml",
    "yaml", "json", "html", "scss", "css", "markdown", "lua", "graphql", "python", "sql",
    "terraform"
}

local prettier_format_command = {formatCommand = "prettierd ${INPUT}", formatStdin = true}
local eslint_lint_command = {
    lintCommand = "./node_modules/.bin/eslint -f unix --stdin --stdin-filename ${INPUT}",
    lintStdin = true,
    lintIgnoreExitCode = true
}

local function get_python_command_path(workspace, command)
    -- Use activated virtualenv.
    if vim.env.VIRTUAL_ENV then return path.join(vim.env.VIRTUAL_ENV, 'bin', command) end

    -- Find and use virtualenv in workspace directory.
    for _, pattern in ipairs({'*', '.*'}) do
        local match = vim.fn.glob(path.join(workspace, pattern, 'pyvenv.cfg'))
        if match ~= '' then return path.join(path.dirname(match), 'bin', command) end
    end

    -- Fallback to system Python.
    return command
end

local M = {}
M.setup = function(on_attach)
    nvim_lsp.efm.setup({
        init_options = {documentFormatting = true, codeAction = true},
        before_init = function(_, config)
            config.settings.languages.python = {
                {
                    lintCommand = get_python_command_path(config.root_dir, 'flake8')
                        .. " --config (find_up .flake8) --stdin-display-name ${INPUT} -",
                    lintStdin = true,
                    lintIgnoreExitCode = true
                }, {
                    lintCommand = get_python_command_path(config.root_dir, 'mypy')
                        .. " --help --show-column-numbers --config-file (find_up .mypy.ini) -C fos -",
                    lintStdin = true,
                    lintFormats = {
                        '%f:%l:%c: %trror: %m', '%f:%l:%c: %tarning: %m', '%f:%l:%c: %tote: %m'
                    },
                    lintIgnoreExitCode = true
                }, {
                    formatCommand = get_python_command_path(config.root_dir, 'isort') .. " --quiet -",
                    formatStdin = true
                }, {
                    formatCommand = get_python_command_path(config.root_dir, 'black') .. " --quiet -",
                    formatStdin = true
                }
            }

        end,
        on_attach = function(client, bufnr)
            if vim.bo.filetype == "lua" then
                client.server_capabilities.document_formatting = false

                vim.api.nvim_command(
                    "au BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync({}, 1500)")
            else
                vim.api.nvim_command("au BufWritePre <buffer> lua vim.lsp.buf.format({}, 1500)")
            end

            on_attach(client, bufnr)
        end,
        filetypes = efm_filetypes,
        settings = {
            rootMarkers = {".git/"},
            lintDebounce = "0.3s",
            languages = {
                elixir = {
                    {
                        lintCommand = "MIX_ENV=test mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
                        lintStdin = true,
                        lintIgnoreExitCode = true,
                        lintFormats = {'%f:%l:%c: %t: %m', '%f:%l: %t: %m'},
                        rootMarkers = {"mix.lock", "mix.exs"}
                    }
                },
                lua = {
                    {
                        formatCommand = "lua-format -i --no-keep-simple-function-one-line --no-break-after-operator --column-limit=100 --break-after-table-lb",
                        formatStdin = true
                    }
                },
                sql = {{formatCommand = "sql-formatter --config ~/.sql-formatter.config.json", formatStdin = true}},
                typescript = {prettier_format_command, eslint_lint_command},
                javascript = {prettier_format_command, eslint_lint_command},
                ["javascript.jsx"] = {prettier_format_command, eslint_lint_command},
                typescriptreact = {prettier_format_command, eslint_lint_command},
                javascriptreact = {prettier_format_command, eslint_lint_command},
                json = {prettier_format_command},
                ["helm.yaml"] = {},
                yaml = {prettier_format_command},
                html = {prettier_format_command},
                scss = {prettier_format_command},
                css = {prettier_format_command},
                graphql = {prettier_format_command},
                markdown = {prettier_format_command},
                terraform = {{formatCommand = "terraform fmt -", formatStdin = true}}
            }
        }
    })
end

return M
