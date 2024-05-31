-- Neovim doesn't support snippets out of the box, so we need to mutate the
-- capabilities we send to the language server to let them know we want snippets.
local M = {}
M.setup = function()
    vim.o.completeopt = "menu,menuone,noselect"

    local cmp = require('cmp')
    cmp.setup {
        snippet = {
            expand = function(args)
                -- For `vsnip` user.
                vim.fn["vsnip#anonymous"](args.body)

                -- For `luasnip` user.
                -- require('luasnip').lsp_expand(args.body)

                -- For `ultisnips` user.
                -- vim.fn["UltiSnips#Anon"](args.body)
            end
        },
        mapping = {
            ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item()),
            ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item()),
            ['<C-d>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.close(),
            ['<CR>'] = cmp.mapping.confirm({select = true})
        },
        sources = {
            {name = 'nvim_lsp'}, -- For vsnip user.
            {name = 'vsnip'}, -- For luasnip user.
            -- { name = 'luasnip' },
            -- For ultisnips user.
            -- { name = 'ultisnips' },
            {name = 'buffer'}
        }
    }
end
return M

-- local t = function(str)
-- return vim.api.nvim_replace_termcodes(str, true, true, true)
-- end

-- local check_back_space = function()
-- local col = vim.fn.col('.') - 1
-- if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
-- return true
-- else
-- return false
-- end
-- end

-- local foz = function

---- Use (s-)tab to:
----- move to prev/next item in completion menuone
----- jump to prev/next snippet's placeholder
-- _G.tab_complete = function()
-- if vim.fn.pumvisible() == 1 then
-- return t "<C-n>"
-- elseif vim.fn.call("vsnip#available", {1}) == 1 then
-- return t "<Plug>(vsnip-expand-or-jump)"
-- elseif check_back_space() then
-- return t "<Tab>"
-- else
-- return vim.fn['compe#complete']()
-- end
-- end
-- _G.s_tab_complete = function()
-- if vim.fn.pumvisible() == 1 then
-- return t "<C-p>"
-- elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
-- return t "<Plug>(vsnip-jump-prev)"
-- else
---- If <S-Tab> is not working in your terminal, change it to <C-h>
-- return t "<C-h>"
-- end
-- end
