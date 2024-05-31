require('nvim-treesitter.configs').setup {
    -- one of "all", or a list of languages
    ensure_installed = {
        "typescript", "javascript", "python", "elixir", "erlang", "rust", "lua", "vim", "ruby",
        "hcl", "go", "terraform"
    },
    ignore_install = {"norg"}, -- List of parsers to ignore installing
    highlight = {
        enable = true, -- false will disable the whole extension
        disable = {"c"}, -- list of language that will be disabled
        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = false
    }
}
