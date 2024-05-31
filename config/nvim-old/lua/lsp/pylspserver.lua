local nvim_lsp = require("lspconfig")
local util = require('lspconfig/util')

local path = util.path

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

local function path_to_config(workspace, config_file)
    local value = path.join(workspace, config_file)
    return value
end

local log = function(message)
    local log_file_path = '/Users/foz/.nvim/debug.log'
    local log_file = io.open(log_file_path, "a")
    io.output(log_file)
    io.write(message .. "\n")
    io.close(log_file)
end

local M = {}
M.setup = function(on_attach, _)
    nvim_lsp.pylsp.setup {
        before_init = function(_, config)
            config.settings.pylsp.plugins = {
                flake8 = {
                    enabled = true,
                    executable = get_python_command_path(config.root_dir, "flake8"),
                    config = path_to_config(config.root_dir, ".flake8"),
                    maxLineLength = 160

                }
            }
            log(vim.inspect(config))
        end,
        on_attach = function(client, bufnr)
            client.server_capabilities.document_formatting = false
            on_attach(client, bufnr)
        end,
        filetypes = {"python"},
        settings = {pylsp = {plugins = {pycodestyle = {enabled = false}}}}
    }

end

return M
