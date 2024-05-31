local nvim_lsp = require("lspconfig")

local path_to_elixirls = vim.fn.expand("~/.lang-servers/elixir-ls/release/language_server.sh")

local elixir_on_attach = function(client, bufnr)
    client.server_capabilities.document_formatting = true
    -- vim.api.nvim_command("au BufWritePost <buffer> vim.lsp.buf.formatting_seq_sync()")

    local function map(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end
    local map_opts = {noremap = true, silent = true}

    map("n", "<c-k>", "<cmd>lua vim.lsp.buf.signature_help()<cr>", map_opts)
    map("n", "1gD", "<cmd>lua vim.lsp.buf.type_definition()<cr>", map_opts)

    -- These have a different style than above because I was fiddling
    -- around and never converted them. Instead of converting them
    -- now, I'm leaving them as they are for this article because this is
    -- what I actually use, and hey, it works ¯\_(ツ)_/¯.
    vim.cmd [[imap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']]
    vim.cmd [[smap <expr> <C-l> vsnip#available(1) ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>']]

    vim.cmd [[imap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>']]
    vim.cmd [[smap <expr> <Tab> vsnip#jumpable(1) ? '<Plug>(vsnip-jump-next)' : '<Tab>']]
    vim.cmd [[imap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>']]
    vim.cmd [[smap <expr> <S-Tab> vsnip#jumpable(-1) ? '<Plug>(vsnip-jump-prev)' : '<S-Tab>']]

end

local M = {}
M.setup = function(on_attach, capabilities)
    nvim_lsp.elixirls.setup({
        cmd = {path_to_elixirls},
        capabilities = capabilities,
        on_attach = function(client, bufnr)

            on_attach(client, bufnr)
            elixir_on_attach(client, bufnr)
        end,
        settings = {elixirLS = {suggestSpecs = true, enableTestLenses = true}}
    })

end

return M
