--[[
 ______   ______     ______  ______   ______   ______   ______   ______
/_____/\ /_____/\   /_____/\/_____/\ /_____/\ /_____/\ /_____/\ /_____/\
\::::_\/_\:::_ \ \  \:::__\/\:::__\/ \:::_ \ \\:::_ \ \\::::_\/_\::::_\/_
 \:\/___/\\:\ \ \ \    /: /  \:\ \  __\:\ \ \ \\:\ \ \ \\:\/___/\\:\/___/\
  \:::._\/ \:\ \ \ \  /::/___ \:\ \/_/\\:\ \ \ \\:\ \ \ \\::___\/_\_::._\:\
   \:\ \    \:\_\ \ \/_:/____/\\:\_\ \ \\:\_\ \ \\:\/.:| |\:\____/\ /____\:\
    \_\/     \_____\/\_______\/ \_____\/ \_____\/ \____/_/ \_____\/ \_____\/



 __  __  _____        ____    ____    ______  __      __      __    __
/\ \/\ \/\  __`\     /\  _`\ /\  _`\ /\  _  \/\ \    /\ \    /\ \  /\ \
\ \ `\\ \ \ \/\ \    \ \ \L\ \ \ \L\_\ \ \L\ \ \ \   \ \ \   \ `\`\\/'/
 \ \ , ` \ \ \ \ \    \ \ ,  /\ \  _\L\ \  __ \ \ \  _\ \ \  _`\ `\ /'
  \ \ \`\ \ \ \_\ \    \ \ \\ \\ \ \L\ \ \ \/\ \ \ \L\ \ \ \L\ \`\ \ \ __
   \ \_\ \_\ \_____\    \ \_\ \_\ \____/\ \_\ \_\ \____/\ \____/  \ \_/\ \
    \/_/\/_/\/_____/     \/_/\/ /\/___/  \/_/\/_/\/___/  \/___/    \/_\ \/
                                                                       \/
 __  __  ____          ____    _____   ____    ____    __
/\ \/\ \/\  _`\       /\  _`\ /\  __`\/\  _`\ /\  _`\ /\ \
\ \ \_\ \ \ \L\_\     \ \ \/\ \ \ \/\ \ \ \L\_\ \,\L\_\ \ \
 \ \  _  \ \  _\L      \ \ \ \ \ \ \ \ \ \  _\L\/_\__ \\ \ \
  \ \ \ \ \ \ \L\ \     \ \ \_\ \ \ \_\ \ \ \L\ \/\ \L\ \ \_\
   \ \_\ \_\ \____/      \ \____/\ \_____\ \____/\ `\____\/\_\
    \/_/\/_/\/___/        \/___/  \/_____/\/___/  \/_____/\/_/
]]
-- FIND MY LSP LOG {{{
-- Uncomment the prints and start nvim to find the goddam LSP logfile again. Cause it ain't where you think!
--
-- vim.g.lua_lsp_log_file = os.getenv "HOME" .. "/.cache/nvim/lsp.log"
-- print "THIS IS THE LOG PATH"
-- print(vim.lsp.get_log_path())
-- vim.lsp.set_log_level "debug"
--
-- }}}
-- Leader key {{{
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ","
vim.g.maplocalleader = ","
-- }}}

vim.opt.title = true
vim.opt.titlestring = "nvim"
vim.opt.lazyredraw = false

-- Layout, Numbers, Clipboard, Tabs, Visual stuff, etc {{{
-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

vim.g.gitcommit_summary_length = 80

-- [[ Setting options ]]
-- See `:help vim.opt`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.opt.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
vim.opt.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Save undo history
vim.opt.undofile = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Preview substitutions live, as you type!
vim.opt.inccommand = "nosplit"

-- Show which line your cursor is on
vim.opt.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10

-- tabs can go to hell
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.shiftwidth = 2

-- Wrapping lines
vim.opt.wrap = false
-- }}}
-- Searching {{{
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
vim.keymap.set("n", "<CR>", ":nohl<CR>")
--}}}
-- Filetypes & Formatting {{{
vim.filetype.add {
  -- Detect and assign filetype based on the extension of the filename
  extension = {
    log = "log",
    conf = "conf",
  },
  -- Detect and apply filetypes based on the entire filename
  filename = {
    [".envrc"] = "bash",
    ["tsconfig.json"] = "jsonc",
  },
  -- Detect and apply filetypes based on certain patterns of the filenames
  pattern = {
    -- INFO: Match filenames like - ".env.example", ".env.local" and so on
    ["%.env%.[%w_.-]+"] = "dotenv",
  },
}

function StripTrailingWhitespace()
  -- Save the current view and search pattern
  local save = vim.fn.winsaveview()
  local last_search = vim.fn.getreg "/"

  -- Remove trailing whitespace and ^M characters
  vim.cmd [[keeppatterns %s/\s\+$//e]]
  vim.cmd [[keeppatterns %s/\%x0D$//e]]

  -- Restore the last search pattern and view
  vim.fn.setreg("/", last_search)
  vim.fn.winrestview(save)
end

-- Remove trailing whitespaces and ^M chars for specified filetypes
local filetypes =
  "c,cpp,css,eelixir,elixir,groovy,heex,html,java,go,leex,liquid,lua,markdown,markdown.spec,php,purescript,javascript,jsx,json,pine,puppet,psl,python,rust,ruby,scss,sh,stylus,twig,xml,yml,perl,sql,md,ts,typescript,terraform,vcl,yml,yaml"
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.split(filetypes, ","),
  callback = function()
    vim.api.nvim_buf_create_user_command(0, "StripTrailingWhitespace", StripTrailingWhitespace, {})
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = 0,
      callback = function()
        vim.cmd "StripTrailingWhitespace"
      end,
    })
  end,
})

-- Setting expandtab, shiftwidth, and softtabstop for specific file types
local expand_filetypes = "haskell,puppet,purs,ruby,yml,javascript,elixir"
vim.api.nvim_create_autocmd("FileType", {
  pattern = vim.split(expand_filetypes, ","),
  callback = function()
    vim.opt_local.expandtab = true
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
  end,
})
-- }}}
-- Basic Keymaps {{{
--  See `:help vim.keymap.set()`

-- Set highlight on search, but clear on pressing <Esc> in normal mode
local function diagnostic_hover()
  local opts = {
    focusable = true, -- Allows you to focus and enter the window
    style = "minimal",
    border = "rounded",
    source = "always",
    header = "",
    prefix = "",
  }
  vim.diagnostic.open_float(nil, opts)
end

-- Diagnostic keymaps
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous [D]iagnostic message" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next [D]iagnostic message" })
vim.keymap.set("n", "H", diagnostic_hover, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
-- }}}
-- Folding {{{
vim.opt.foldenable = true
vim.opt.foldnestmax = 10
vim.opt.foldlevelstart = 10
vim.opt.foldmethod = "indent"
-- space open/closes folds
vim.keymap.set("n", "<space>", "za", { desc = "Toggle Fold" })
-- }}}

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking (copying) text",
  group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- [[ Install `lazy.nvim` plugin manager ]]
--    See `:help lazy.nvim.txt` or https://github.com/folke/lazy.nvim for more info
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
--
--  To check the current status of your plugins, run
--    :Lazy
--
--  You can press `?` in this menu for help. Use `:q` to close the window
--
--  To update plugins you can run
--    :Lazy update
--
-- NOTE: Here is where you install your plugins.
require("lazy").setup({
  -- NOTE: Plugins can be added with a link (or for a github repo: 'owner/repo' link).
  "tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

  -- NOTE: Plugins can also be added by using a table,
  -- with the first argument being the link and the following
  -- keys can be used to configure plugin behavior/loading/etc.
  --
  -- Use `opts = {}` to force a plugin to be loaded.
  --
  --  This is equivalent to:
  --    require('Comment').setup({})

  -- "gc" to comment visual regions/lines
  { "numToStr/Comment.nvim", opts = {} },
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    config = function()
      vim.g.tmux_navigator_no_mappings = 1 -- Disable default mappings
      -- Set the keybindings directly here to avoid lazy loading
      vim.api.nvim_set_keymap("n", "<C-h>", ":TmuxNavigateLeft<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<C-j>", ":TmuxNavigateDown<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<C-k>", ":TmuxNavigateUp<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<C-l>", ":TmuxNavigateRight<CR>", { noremap = true, silent = true })
      vim.api.nvim_set_keymap("n", "<C-\\>", ":TmuxNavigatePrevious<CR>", { noremap = true, silent = true })
    end,
  },

  -- "christoomey/vim-tmux-navigator",
  "roman/golden-ratio",
  -- "mhinz/vim-startify",
  "easymotion/vim-easymotion",
  "mechatroner/rainbow_csv",
  "github/copilot.vim",
  {
    "rubiin/fortune.nvim",
    config = function()
      require("fortune").setup { content_type = "quotes", max_width = 1000, display_format = "mixed" }
    end,
  },
  -- Here is a more advanced example where we pass configuration
  -- options to `gitsigns.nvim`. This is equivalent to the following Lua:
  --    require('gitsigns').setup({ ... })
  --
  -- See `:help gitsigns` to understand what the configuration keys do
  { -- Adds git related signs to the gutter, as well as utilities for managing changes
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
    },
  },

  -- NOTE: Plugins can also be configured to run Lua code when they are loaded.
  --
  --
  --t
  -- This is often very useful to both group configuration, as well as handle
  -- lazy loading plugins that don't need to be loaded immediately at startup.
  --
  -- For example, in the following configuration, we use:
  --  event = 'VimEnter'
  --
  -- which loads which-key before all the UI elements are loaded. Events can be
  -- normal autocommands events (`:help autocmd-events`).
  --
  -- Then, because we use the `config` key, the configuration only runs
  -- after the plugin has been loaded:
  --  config = function() ... end

  { -- Useful plugin to show you pending keybinds.
    "folke/which-key.nvim",
    event = "VimEnter", -- Sets the loading event to 'VimEnter'
    config = function() -- This is the function that runs, AFTER loading
      require("which-key").setup()
    end,
  },

  -- NOTE: Plugins can specify dependencies.
  --
  -- The dependencies are proper plugin specifications as well - anything
  -- you do for a plugin at the top level, you can do for a dependency.
  --
  -- Use the `dependencies` key to specify the dependencies of a particular plugin

  { -- Fuzzy Finder (files, lsp, etc)
    "nvim-telescope/telescope.nvim",
    event = "VimEnter",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { -- If encountering errors, see telescope-fzf-native README for installation instructions
        "nvim-telescope/telescope-fzf-native.nvim",

        -- `build` is used to run some command when the plugin is installed/updated.
        -- This is only run then, not every time Neovim starts up.
        build = "make",

        -- `cond` is a condition used to determine whether this plugin should be
        -- installed and loaded.
        cond = function()
          return vim.fn.executable "make" == 1
        end,
      },
      { "nvim-telescope/telescope-ui-select.nvim" },

      -- Useful for getting pretty icons, but requires a Nerd Font.
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
      {
        "isak102/telescope-git-file-history.nvim",
        dependencies = {
          "nvim-lua/plenary.nvim",
          "tpope/vim-fugitive",
        },
      },
    },
    config = function()
      -- Telescope is a fuzzy finder that comes with a lot of different things that
      -- it can fuzzy find! It's more than just a "file finder", it can search
      -- many different aspects of Neovim, your workspace, LSP, and more!
      --
      -- The easiest way to use Telescope, is to start by doing something like:
      --  :Telescope help_tags
      --
      -- After running this command, a window will open up and you're able to
      -- type in the prompt window. You'll see a list of `help_tags` options and
      -- a corresponding preview of the help.
      --
      -- Two important keymaps to use while in Telescope are:
      --  - Insert mode: <c-/>
      --  - Normal mode: ?
      --
      -- This opens a window that shows you all of the keymaps for the current
      -- Telescope picker. This is really useful to discover what Telescope can
      -- do as well as how to actually do it!

      -- [[ Configure Telescope ]]
      -- See `:help telescope` and `:help telescope.setup()`
      require("telescope").setup {
        -- You can put your default mappings / updates / etc. in here
        --  All the info you're looking for is in `:help telescope.setup()`
        --
        -- defaults = {
        --   mappings = {
        --     i = { ['<c-enter>'] = 'to_fuzzy_refine' },
        --   },
        -- },
        -- pickers = {}
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown(),
          },
          ["git_file_history"] = {},
        },
        defaults = {
          file_ignore_patterns = {
            ".git",
            "node_modules",
            "build",
            "dist",
            "yarn.lock",
          },
          hidden = true,
        },
        pickers = {
          find_files = {
            hidden = true,
            -- needed to exclude some files & dirs from general search
            -- when not included or specified in .gitignore
            find_command = {
              "rg",
              "--files",
              "--no-ignore",
              "--hidden",
              "--glob=!**/.git/*",
              "--glob=!**/.idea/*",
              "--glob=!**/.vscode/*",
              "--glob=!**/build/*",
              "--glob=!**/dist/*",
              "--glob=!**/yarn.lock",
              "--glob=!**/package-lock.json",
            },
          },
        },
      }
      -- Enable Telescope extensions if they are installed
      pcall(require("telescope").load_extension, "fzf")
      pcall(require("telescope").load_extension, "ui-select")
      pcall(require("telescope").load_extension "git_file_history")

      -- See `:help telescope.builtin`
      local builtin = require "telescope.builtin"
      vim.keymap.set("n", "<leader>sh", builtin.help_tags, { desc = "[S]earch [H]elp" })
      vim.keymap.set("n", "<leader>sk", builtin.keymaps, { desc = "[S]earch [K]eymaps" })
      vim.keymap.set("n", "<leader>sf", builtin.find_files, { desc = "[S]earch [F]iles" })
      vim.keymap.set("n", "<leader>ss", builtin.builtin, { desc = "[S]earch [S]elect Telescope" })
      vim.keymap.set("n", "<leader>sw", builtin.grep_string, { desc = "[S]earch current [W]ord" })
      vim.keymap.set("n", "<leader>sw", function()
        builtin.grep_string {
          additional_args = function()
            return { "--no-ignore" }
          end,
        }
      end, { desc = "[S]earch current [W]ord (no ignore)" })
      vim.keymap.set("n", "<leader>sg", builtin.live_grep, { desc = "[S]earch by [G]rep" })
      vim.keymap.set("n", "<leader>sG", function()
        builtin.live_grep {
          additional_args = function()
            return { "--no-ignore" }
          end,
        }
      end, { desc = "[S]earch by [g]rep (no ignore)" })
      vim.keymap.set("n", "<leader>sd", builtin.diagnostics, { desc = "[S]earch [D]iagnostics" })
      vim.keymap.set("n", "<leader>sr", builtin.resume, { desc = "[S]earch [R]esume" })
      vim.keymap.set("n", "<leader>s.", builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })

      -- Slightly advanced example of overriding default behavior and theme
      vim.keymap.set("n", "<leader>/", function()
        -- You can pass additional configuration to Telescope to change the theme, layout, etc.
        builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
          winblend = 10,
          previewer = false,
          max_width = 0.8,
        })
      end, { desc = "[/] Fuzzily search in current buffer" })

      -- It's also possible to pass additional configuration options.
      --  See `:help telescope.builtin.live_grep()` for information about particular keys
      vim.keymap.set("n", "<leader>s/", function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = "Live Grep in Open Files",
        }
      end, { desc = "[S]earch [/] in Open Files" })

      -- Shortcut for searching your Neovim configuration files
      vim.keymap.set("n", "<leader>sn", function()
        builtin.find_files { cwd = vim.fn.stdpath "config" }
      end, { desc = "[S]earch [N]eovim files" })

      vim.keymap.set("n", "<leader>gh", require("telescope").extensions.git_file_history.git_file_history, { desc = "[G]it [H]istory in Telescope" })
    end,
  },
  {
    "ryanoasis/vim-devicons", -- or whatever the correct plugin name is
    config = function()
      vim.defer_fn(function()
        vim.cmd [[if exists("g:loaded_webdevicons") | call webdevicons#refresh() | endif]]
      end, 0) -- Defers the execution until Neovim is idle
    end,
  },
  {
    "preservim/nerdtree",
    dependencies = {
      { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
      "ryanoasis/vim-devicons",
      "Xuyuanp/nerdtree-git-plugin",
      "vwxyutarooo/nerdtree-devicons-syntax",
    },
    init = function()
      vim.g.NERDTreeMapJumpNextSibling = ""
      vim.g.NERDTreeMapJumpPrevSibling = ""
    end,
    config = function()
      vim.g.NERDTreeShutUp = 1
      vim.g.NERDTreeShowHidden = 1
      vim.g.NERDTreeMapJumpNextSibling = ""
      vim.g.NERDTreeMapJumpPrevSibling = ""
      vim.keymap.set("n", "<C-e>", ":NERDTreeToggle<CR>", { desc = "Toggle NERDTree" })
      vim.NERDTreeShowBookmarks = 1
      vim.NERDTreeIgnore = "['.py[cd]$', '~$', '.swo$', '.swp$', '^.git$', '^.hg$', '^.svn$', '.bzr$']"
      vim.NERDTreeChDirMode = 0
      vim.NERDTreeMouseMode = 0
      vim.NERDTreeShowHidden = 1
      vim.NERDTreeQuitOnOpen = 1
    end,
  },
  { -- LSP Configuration & Plugins
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath for Neovim
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

      -- Useful status updates for LSP.
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { "j-hui/fidget.nvim", opts = {} },

      -- `neodev` configures Lua LSP for your Neovim config, runtime and plugins
      -- used for completion, annotations and signatures of Neovim apis
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
            },
          },
        },
      })

      -- Brief aside: **What is LSP?**
      --
      -- LSP is an initialism you've probably heard, but might not understand what it is.
      --
      -- LSP stands for Language Server Protocol. It's a protocol that helps editors
      -- and language tooling communicate in a standardized fashion.
      --
      -- In general, you have a "server" which is some tool built to understand a particular
      -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
      -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
      -- processes that communicate with some "client" - in this case, Neovim!
      --
      -- LSP provides Neovim with features like:
      --  - Go to definition
      --  - Find references
      --  - Autocompletion
      --  - Symbol Search
      --  - and more!
      --
      -- Thus, Language Servers are external tools that must be installed separately from
      -- Neovim. This is where `mason` and related plugins come into play.
      --
      -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
      -- and elegantly composed help section, `:help lsp-vs-treesitter`

      --  This function gets run when an LSP attaches to a particular buffer.
      --    That is to say, every time a new file is opened that is associated with
      --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
      --    function will be executed to configure the current buffer
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
        callback = function(event)
          -- NOTE: Remember that Lua is a real programming language, and as such it is possible
          -- to define small helper and utility functions so you don't have to repeat yourself.
          --
          -- In this case, we create a function that lets us more easily define mappings specific
          -- for LSP related items. It sets the mode, buffer and description for us each time.
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          vim.diagnostic.config {
            signs = {
              text = {
                [vim.diagnostic.severity.ERROR] = "",
                [vim.diagnostic.severity.WARN] = "",
                [vim.diagnostic.severity.INFO] = "󰋼",
                [vim.diagnostic.severity.HINT] = "󰌵",
              },
            },
          }

          vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            border = "rounded",
            margin = { 10, 10, 10, 10 },
          })

          vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
          -- Automatically update diagnostics ... from
          -- https://github.com/folke/dot/blob/master/config/nvim/lua/config/lsp/diagnostics.lua
          vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
            underline = true,
            update_in_insert = false,
            virtual_text = {
              source = true,
              spacing = 4,
              -- prefix = "● "
            },
            float = { source = true },
            severity_sort = true,
          })

          -- Jump to the definition of the word under your cursor.
          --  This is where a variable was first declared, or where a function is defined, etc.
          --  To jump back, press <C-t>.
          map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")

          -- Find references for the word under your cursor.
          map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")

          -- Jump to the implementation of the word under your cursor.
          --  Useful when your language has ways of declaring types without an actual implementation.
          map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")

          -- Jump to the type of the word under your cursor.
          --  Useful when you're not sure what type a variable is and you want to see
          --  the definition of its *type*, not where it was *defined*.
          map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")

          -- Rename the variable under your cursor.
          --  Most Language Servers support renaming across files, etc.
          map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")

          -- Execute a code action, usually your cursor needs to be on top of an error
          -- or a suggestion from your LSP for this to activate.
          map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap.
          map("K", vim.lsp.buf.hover, "Hover Documentation")

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

          -- Can't do these inside LSP attach
          -- map("[d", vim.diagnostic.goto_prev, "Go to previous [D]iagnostic message")
          -- map("]d", vim.diagnostic.goto_nex, "Go to next [D]iagnostic message")
          -- map("<leader>E", vim.diagnostic.open_float, "Show diagnostic [E]rror messages")
          -- map("<leader>q", vim.diagnostic.setloclist, "Open diagnostic [Q]uickfix list")

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.server_capabilities.documentHighlightProvider then
            vim.api.nvim_create_autocmd("LspDetach", {
              callback = function(args)
                vim.api.nvim_clear_autocmds {
                  buffer = args.buf,
                  event = { "CursorHold", "CursorHoldI", "CursorMoved", "CursorMovedI" },
                }
              end,
            })

            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.document_highlight,
            })

            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              callback = vim.lsp.buf.clear_references,
            })
          end
        end,
      })

      -- LSP servers and clients are able to communicate to each other what features they support.
      --  By default, Neovim doesn't support everything that is in the LSP specification.
      --  When you add nvim-cmp, luasnip, etc. Neovim now has *more* capabilities.
      --  So, we create new capabilities with nvim cmp, and then broadcast that to the servers.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

      local original_handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
      vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
        if err then
          vim.notify("LSP diagnostics error: " .. vim.inspect(err))
        end
        return original_handler(err, result, ctx, config)
      end

      -- Enable the following language servers
      --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
      --
      --  Add any additional override configuration in the following tables. Available keys are:
      --  - cmd (table): Override the default command used to start the server
      --  - filetypes (table): Override the default list of associated filetypes for the server
      --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
      --  - settings (table): Override the default settings passed when initializing the server.
      --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
      local function get_python_path(workspace)
        local util = require "lspconfig/util"

        local path = util.path

        -- Use activated virtualenv.
        if vim.env.VIRTUAL_ENV then
          return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
        end

        -- Find and use virtualenv in workspace directory.
        for _, pattern in ipairs { "*", ".*" } do
          local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
          if match ~= "" then
            return path.join(path.dirname(match), "bin", "python")
          end
        end

        -- Fallback to system Python.
        return "python"
      end

      local function get_python_command_path(workspace, command)
        local util = require "lspconfig/util"

        local path = util.path
        -- Use activated virtualenv.
        if vim.env.VIRTUAL_ENV then
          local resolved = path.join(vim.env.VIRTUAL_ENV, "bin", command)
          vim.lsp.log.info("Using VIRTUAL_ENV path: " .. resolved)
          return path.join(vim.env.VIRTUAL_ENV, "bin", command)
        end

        -- Find and use virtualenv in workspace directory.
        for _, pattern in ipairs { "*", ".*" } do
          local match = vim.fn.glob(path.join(workspace, pattern, "pyvenv.cfg"))
          if match ~= "" then
            local resolved = path.join(path.dirname(match), "bin", command)
            vim.lsp.log.info("Using workspace venv path: " .. resolved)
            return path.join(path.dirname(match), "bin", command)
          end
        end

        -- Fallback to system Python.
        return command
      end

      local eslint_lint_command = {
        lintCommand = "./node_modules/.bin/eslint -f unix --stdin --stdin-filename ${INPUT}",
        lintStdin = true,
        lintIgnoreExitCode = true,
      }

      local prettier_format_command = { formatCommand = "prettierd ${INPUT}", formatStdin = true }

      local efm_filetypes = {
        "css",
        "elixir",
        "graphql",
        "helm.yaml",
        "html",
        "javascript",
        "javascriptreact",
        "json",
        "jsx",
        "lua",
        "markdown",
        "python",
        "scss",
        "sql",
        "terraform",
        "typescript",
        "typescriptreact",
        "yaml",
      }

      local servers = {
        -- clangd = {},
        -- gopls = {},
        -- pylsp = {},
        pyright = {
          before_init = function(_, config)
            config.settings.python.pythonPath = get_python_path(config.root_dir)
          end,
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              typeCheckingMode = "basic",
            },
          },
        },
        efm = {
          cmd = {
            "efm-langserver",
            "-logfile",
            "/tmp/efm.log",
            "-loglevel",
            "10",
          },
          init_options = { documentFormatting = true, codeAction = true },
          before_init = function(_, config)
            config.settings.languages.python = {
              {
                lintCommand = get_python_command_path(config.root_dir, "flake8") .. " --config (find_up .flake8) --stdin-display-name ${INPUT} -",
                lintStdin = true,
                lintIgnoreExitCode = true,
              },
              {
                lintCommand = get_python_command_path(config.root_dir, "mypy") .. " --help --show-column-numbers --config-file (find_up .mypy.ini) -C fos -",
                lintStdin = true,
                lintFormats = {
                  "%f:%l:%c: %trror: %m",
                  "%f:%l:%c: %tarning: %m",
                  "%f:%l:%c: %tote: %m",
                },
                lintIgnoreExitCode = true,
              },
              {
                formatCommand = get_python_command_path(config.root_dir, "isort") .. " --quiet -",
                formatStdin = true,
              },
              {
                formatCommand = get_python_command_path(config.root_dir, "black") .. " --quiet --stdin-filename ${INPUT} -",
                formatStdin = true,
              },
            }
          end,
          filetypes = efm_filetypes,
          settings = {
            rootMarkers = { ".git/" },
            lintDebounce = "2s",
            languages = {
              elixir = {
                {
                  lintCommand = "MIX_ENV=test mix credo suggest --format=flycheck --read-from-stdin ${INPUT}",
                  lintStdin = true,
                  lintIgnoreExitCode = true,
                  lintFormats = { "%f:%l:%c: %t: %m", "%f:%l: %t: %m" },
                  rootMarkers = { "mix.lock", "mix.exs" },
                },
              },
              sql = { { formatCommand = "sql-formatter --config ~/.sql-formatter.config.json", formatStdin = true } },
              typescript = { prettier_format_command, eslint_lint_command },
              javascript = { prettier_format_command, eslint_lint_command },
              ["javascript.jsx"] = { prettier_format_command, eslint_lint_command },
              typescriptreact = { prettier_format_command, eslint_lint_command },
              javascriptreact = { prettier_format_command, eslint_lint_command },
              json = { prettier_format_command },
              ["helm.yaml"] = {},
              yaml = { prettier_format_command },
              html = { prettier_format_command },
              scss = { prettier_format_command },
              css = { prettier_format_command },
              graphql = { prettier_format_command },
              markdown = { prettier_format_command },
              terraform = { { formatCommand = "terraform fmt -", formatStdin = true } },
            },
          },
        },
        -- rust_analyzer = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`tsserver`) will work just fine
        ts_ls = {},
        --

        lua_ls = {
          -- cmd = {...},
          -- filetypes = { ...},
          -- capabilities = {},
          settings = {
            Lua = {
              completion = {
                callSnippet = "Replace",
              },
              -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },

        elixirls = {
          elixirLS = {
            dialyzerEnabled = true,
            suggestSpecs = true,
            enableTestLenses = true,
          },
        },

        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json"] = "**/workflow/*",
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
              },
            },
          },
        },
        ["copilot-language-server"] = {},
        jsonls = {},
      }

      -- Ensure the servers and tools above are installed
      --  To check the current status of installed tools and/or manually install
      --  other tools, you can run
      --    :Mason
      --
      --  You can press `g?` for help in this menu.
      require("mason").setup()

      -- You can add other tools here that you want Mason to install
      -- for you, so that they are available from within Neovim.
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, {
        "stylua", -- Used to format Lua code
      })
      require("mason-tool-installer").setup { ensure_installed = ensure_installed }

      require("mason-lspconfig").setup {
        handlers = {
          function(server_name)
            if server_name == "efm" then
              -- Skip EFM here - we'll handle it separately
              return
            end

            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
            require("lspconfig")[server_name].setup(server)
          end,
        },
      }

      -- Setup EFM manually with your full config
      local efm_config = servers.efm or {}
      efm_config.capabilities = vim.tbl_deep_extend("force", {}, capabilities, efm_config.capabilities or {})

      vim.lsp.config("efm", efm_config)
    end,
  },

  { -- Autoformat
    "stevearc/conform.nvim",
    lazy = false,
    keys = {
      {
        "<leader>f",
        function()
          require("conform").format { async = true, lsp_fallback = true }
        end,
        mode = "",
        desc = "[F]ormat buffer",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        -- Disable "format_on_save lsp_fallback" for languages that don't
        -- have a well standardized coding style. You can add additional
        -- languages here or re-enable it for the disabled ones.
        local disable_filetypes = { c = true, cpp = true }
        return {
          timeout_ms = 500,
          lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
        }
      end,
      formatters_by_ft = {
        lua = { "stylua" },
        -- Conform can also run multiple formatters sequentially
        python = { "isort", "black" },
        --
        -- You can use a sub-list to tell conform to run *until* a formatter
        -- is found.
        -- javascript = { { "prettierd", "prettier" } },
      },
    },
  },

  { -- Autocompletion
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      -- Snippet Engine & its associated nvim-cmp source
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          -- Build Step is needed for regex support in snippets.
          -- This step is not supported in many windows environments.
          -- Remove the below condition to re-enable on windows.
          if vim.fn.has "win32" == 1 or vim.fn.executable "make" == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
        dependencies = {
          -- `friendly-snippets` contains a variety of premade snippets.
          --    See the README about individual language/framework/plugin snippets:
          --    https://github.com/rafamadriz/friendly-snippets
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function()
          --     require('luasnip.loaders.from_vscode').lazy_load()
          --   end,
          -- },
        },
      },
      "saadparwaiz1/cmp_luasnip",

      -- Adds other completion capabilities.
      --  nvim-cmp does not ship with all sources by default. They are split
      --  into multiple repos for maintenance purposes.
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
    },
    config = function()
      -- See `:help cmp`
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      luasnip.config.setup {}

      cmp.setup {
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = { completeopt = "menu,menuone,noinsert" },

        -- For an understanding of why these mappings were
        -- chosen, you will need to read `:help ins-completion`
        --
        -- No, but seriously. Please read `:help ins-completion`, it is really good!
        mapping = cmp.mapping.preset.insert {
          -- Select the [n]ext item
          ["<C-n>"] = cmp.mapping.select_next_item(),
          -- Select the [p]revious item
          ["<C-p>"] = cmp.mapping.select_prev_item(),

          -- Scroll the documentation window [b]ack / [f]orward
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),

          -- Accept ([y]es) the completion.
          --  This will auto-import if your LSP supports it.
          --  This will expand snippets if the LSP sent a snippet.
          ["<C-y>"] = cmp.mapping.confirm { select = true },

          -- Manually trigger a completion from nvim-cmp.
          --  Generally you don't need this, because nvim-cmp will display
          --  completions whenever it has completion options available.
          ["<C-Space>"] = cmp.mapping.complete {},

          -- Think of <c-l> as moving to the right of your snippet expansion.
          --  So if you have a snippet that's like:
          --  function $name($args)
          --    $body
          --  end
          --
          -- <c-l> will move you to the right of each of the expansion locations.
          -- <c-h> is similar, except moving you backwards.
          ["<C-l>"] = cmp.mapping(function()
            if luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            end
          end, { "i", "s" }),
          ["<C-h>"] = cmp.mapping(function()
            if luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            end
          end, { "i", "s" }),

          -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
          --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        },
      }
    end,
  },

  { -- You can easily change to a different colorscheme.
    -- Change the name of the colorscheme plugin below, and then
    -- change the command in the config to whatever the name of that colorscheme is.
    --
    -- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
    "EdenEast/nightfox.nvim",
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {
      fox = "dayfox",
      transparent = true,
      italic_keywords = true,
      terminal_colors = true,
      styles = {
        functions = "italic,bold", -- styles can be a comma separated list
      },
      inverse = {
        match_paren = true, -- inverse the highlighting of match_parens
      },
      colors = {
        red = "#FFCCCB", -- Override the red color for MAX POWER
      },
    },
    init = function()
      -- Load the colorscheme here.
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme "nordfox"

      -- You can configure highlights by doing something like:
      vim.cmd.hi "Comment gui=none"
    end,
  },

  -- Highlight todo, notes, etc in comments
  {
    "folke/todo-comments.nvim",
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
  },

  { -- Collection of various small independent plugins/modules
    "echasnovski/mini.nvim",
    config = function()
      -- Better Around/Inside textobjects
      --
      -- Examples:
      --  - va)  - [V]isually select [A]round [)]paren
      --  - yinq - [Y]ank [I]nside [N]ext [']quote
      --  - ci'  - [C]hange [I]nside [']quote
      require("mini.ai").setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      --
      -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
      -- - sd'   - [S]urround [D]elete [']quotes
      -- - sr)'  - [S]urround [R]eplace [)] [']
      require("mini.surround").setup()
      require("mini.pairs").setup()

      -- Simple and easy statusline.
      --  You could remove this setup call if you don't like it,
      --  and try some other statusline plugin
      local statusline = require "mini.statusline"
      -- set use_icons to true if you have a Nerd Font
      statusline.setup { use_icons = vim.g.have_nerd_font }

      -- You can configure sections in the statusline by overriding their
      -- default behavior. For example, here we set the section for
      -- cursor location to LINE:COLUMN
      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return "%2l:%-2v"
      end

      -- Function to wrap lines to a specified width using recursion
      local format_fortune = function(fortune, max_width)
        local wrapped_lines = {}

        local function wrap_line(line)
          if #line <= max_width then
            return { line }
          end

          local sub_line = line:sub(1, max_width)
          local space_index = sub_line:find "%s[^%s]*$" -- Find the last space in the substring
          if space_index then
            sub_line = sub_line:sub(1, space_index - 1)
          end

          local remaining_line = line:sub(#sub_line + 1):gsub("^%s+", "") -- Remove leading spaces from the remaining line
          local wrapped_remaining = wrap_line(remaining_line)

          return { sub_line, unpack(wrapped_remaining) }
        end

        for _, line in ipairs(fortune) do
          line = line:gsub("^%s+", "")
          local wrapped_line = wrap_line(line)
          for _, l in ipairs(wrapped_line) do
            table.insert(wrapped_lines, l)
          end
        end

        return table.concat(wrapped_lines, "\n")
      end

      local logo = table.concat({
        "  █████▒▒█████  ▒███████▒ ▄████▄   ▒█████  ▓█████▄ ▓█████   ██████ ",
        "▓██   ▒▒██▒  ██▒▒ ▒ ▒ ▄▀░▒██▀ ▀█  ▒██▒  ██▒▒██▀ ██▌▓█   ▀ ▒██    ▒ ",
        "▒████ ░▒██░  ██▒░ ▒ ▄▀▒░ ▒▓█    ▄ ▒██░  ██▒░██   █▌▒███   ░ ▓██▄   ",
        "░▓█▒  ░▒██   ██░  ▄▀▒   ░▒▓▓▄ ▄██▒▒██   ██░░▓█▄   ▌▒▓█  ▄   ▒   ██▒",
        "░▒█░   ░ ████▓▒░▒███████▒▒ ▓███▀ ░░ ████▓▒░░▒████▓ ░▒████▒▒██████▒▒",
        " ▒ ░   ░ ▒░▒░▒░ ░▒▒ ▓░▒░▒░ ░▒ ▒  ░░ ▒░▒░▒░  ▒▒▓  ▒ ░░ ▒░ ░▒ ▒▓▒ ▒ ░",
        " ░       ░ ▒ ▒░ ░░▒ ▒ ░ ▒  ░  ▒     ░ ▒ ▒░  ░ ▒  ▒  ░ ░  ░░ ░▒  ░ ░",
        " ░ ░   ░ ░ ░ ▒  ░ ░ ░ ░ ░░        ░ ░ ░ ▒   ░ ░  ░    ░   ░  ░  ░  ",
        "           ░ ░    ░ ░    ░ ░          ░ ░     ░       ░  ░      ░  ",
        "                ░        ░                  ░                      ",
      }, "\n")

      require("mini.starter").setup {
        autoopen = true,
        evaluate_single = true,
        header = logo,
        items = {
          { name = "New file", action = "enew", section = "Actions" },
          { name = "Open file", action = "Telescope find_files", section = "Actions" },
          { name = "Recent files", action = "Telescope oldfiles", section = "Actions" },
        },
        footer = function()
          local fortune = require("fortune").get_fortune()
          -- Split fortune into multiple lines
          local max_width = 60
          local wrapped_fortune = format_fortune(fortune, max_width)
          return wrapped_fortune
        end,
      }
    end,
  },
  { -- Highlight, edit, and navigate code
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { "bash", "c", "html", "lua", "luadoc", "markdown", "vim", "vimdoc" },
      -- Autoinstall languages that are not installed
      auto_install = true,
      highlight = {
        enable = true,
        -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
        --  If you are experiencing weird indenting issues, add the language to
        --  the list of additional_vim_regex_highlighting and disabled languages for indent.
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = { enable = true, disable = { "ruby" } },
    },
    config = function(_, opts)
      -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup(opts)

      -- There are additional nvim-treesitter modules that you can use to interact
      -- with nvim-treesitter. You should go explore a few and see what interests you:
      --
      --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
      --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
      --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
    end,
  },
  "triglav/vim-visual-increment",
  "pinecoders/vim-pine-script",
  {
    "wesQ3/vim-windowswap",
    config = function()
      vim.g.windowswap_map_keys = 0
      vim.keymap.set("n", "<leader>ew", ":call WindowSwap#EasyWindowSwap()<CR>", { desc = "Swap window" })
    end,
  },
  "tpope/vim-obsession",

  -- The following two comments only work if you have downloaded the kickstart repo, not just copy pasted the
  -- init.lua. If you want these files, they are in the repository, so you can just download them and
  -- place them in the correct locations.

  -- NOTE: Next step on your Neovim journey: Add/Configure additional plugins for Kickstart
  --
  --  Here are some example plugins that I've included in the Kickstart repository.
  --  Uncomment any of the lines below to enable them (you will need to restart nvim).
  --
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    This is the easiest way to modularize your config.
  --
  --  Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --    For additional information, see `:help lazy.nvim-lazy.nvim-structuring-your-plugins`
  -- { import = 'custom.plugins' },
  {
    "ravitemer/mcphub.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    build = "npm install -g mcp-hub@latest", -- Installs `mcp-hub` node binary globally
    config = function()
      require("mcphub").setup {
        config = vim.fn.expand "~/.config/mcphub/servers.json",
        auto_approve = false, -- Auto approve mcp tool calls
        auto_toggle_mcp_servers = true,
      }
    end,
  },
}, {
  ui = {
    -- If you are using a Nerd Font: set icons to an empty table which will use the
    -- default lazy.nvim defined Nerd Font icons, otherwise define a unicode icons table
    icons = vim.g.have_nerd_font and {} or {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})

-- Autocommand that sets foldmethod and foldlevel for init.lua only
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "init.lua",
  callback = function(args)
    -- Check if the opened init.lua is the one from your Neovim configuration directory
    -- if args.file == vim.fn.stdpath "config" .. "/init.lua" then
    vim.opt_local.foldmethod = "marker"
    vim.opt_local.foldlevel = 0
    -- end
  end,
})
-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
