local util = require("utils")
vim.o.completeopt = "menu,menuone,noselect"

local M = {}
M.setup = function()
    require('compe').setup({
        enabled = true,
        autocomplete = true,
        debug = false,
        min_length = 1,
        preselect = 'enable',
        throttle_time = 80,
        source_timeout = 200,
        resolve_timeout = 800,
        incomplete_delay = 400,
        max_abbr_width = 100,
        max_kind_width = 100,
        max_menu_width = 100,
        documentation = {
            border = "rounded", -- the border option is the same as `|help nvim_open_win|`
            winhighlight = "NormalFloat:CompeDocumentation,FloatBorder:CompeDocumentationBorder",
            max_width = 120,
            min_width = 60,
            max_height = math.floor(vim.o.lines * 0.3),
            min_height = 1
        },

        source = {
            path = true,
            buffer = true,
            tags = true,
            calc = true,
            nvim_lsp = true,
            nvim_lua = true,
            vsnip = true
        }
    })

    util.imap("<C-Space>", "compe#complete()", {expr = true, noremap = true})
    util.imap("<C-c>", "compe#confirm(luaeval(\"require 'nvim-autopairs'.autopairs_cr()\"))",
              {expr = true, noremap = true})
    util.imap("<C-e>", "compe#close('<C-e>')", {expr = true, noremap = true})

    -- inoremap <silent><expr> <C-Space> compe#complete()
    -- inoremap <silent><expr> <CR>      compe#confirm(luaeval("require 'nvim-autopairs'.autopairs_cr()"))
    -- inoremap <silent><expr> <C-e>     compe#close('<C-e>')
    -- inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
    -- inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })

    -- local function complete()
    -- if vim.fn.pumvisible() == 1 then
    -- return vim.fn["compe#confirm"]({keys = "<cr>", select = true})
    -- else
    -- return require("nvim-autopairs").autopairs_cr()
    -- end
    -- end

    -- util.imap("<CR>", complete, {expr = true, noremap = true})
    vim.cmd([[autocmd User CompeConfirmDone silent! lua vim.lsp.buf.signature_help()]])
end
return M
