" Setup {{{
set shell=/bin/sh
set nocompatible
filetype off
set encoding=utf-8
set title                   " Put title in terminal window
set exrc
set secure
set backupcopy=yes
set viminfo+=n~/.nvim/viminfo
" }}}
" Plugins {{{
" Setup Plug
" manually added file to local/nvim/autoload/plug.vim
" Might need to update manually too
" Specify a directory for plugins
" - For Neovim: stdpath('data') . '/plugged'
" - Avoid using standard Vim directory names like 'plugin'

" Install vim-plug if not found
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin('~/.nvim/plugged')

Plug 'neovim/nvim-lspconfig'
Plug 'windwp/nvim-autopairs'
Plug 'KeitaNakamura/neodark.vim'
Plug 'altercation/vim-colors-solarized'
Plug 'bkad/CamelCaseMotion'
Plug 'christoomey/vim-tmux-navigator'
Plug 'ctrlpvim/ctrlp.vim'
Plug 'easymotion/vim-easymotion'
Plug 'github/copilot.vim'
Plug 'mhinz/vim-startify'
Plug 'davidoc/taskpaper.vim'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-nvim-lua'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-nvim-lsp'
"Plug 'hrsh7th/cmp-vsnip'
"Plug 'hrsh7th/nvim-compe'
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'
"Plug 'hrsh7th/vim-vsnip-integ'
Plug 'kristijanhusak/vim-hybrid-material'
"To get this working you need to install a nerd font or patch an existing font
"with the nerdfont font-patcher: https://github.com/ryanoasis/nerd-fonts
"Clone the entire repo to get the script working
Plug 'nvim-tree/nvim-web-devicons'
Plug 'ryanoasis/vim-devicons'
Plug 'mbbill/undotree'
Plug 'mxw/vim-jsx'
Plug 'mechatroner/rainbow_csv'
Plug 'nvim-lua/plenary.nvim'
"Plug 'nvim-lua/completion-nvim'
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}  " We recommend updating the parsers on update
Plug 'preservim/nerdtree'
Plug 'vwxyutarooo/nerdtree-devicons-syntax'
Plug 'roman/golden-ratio'
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'triglav/vim-visual-increment' " This guy lets you increment numbers under visual highlight <C-V> to highlight, then <C-A> to increment
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'w0ng/vim-hybrid'
Plug 'wesQ3/vim-windowswap'
Plug 'b4b4r07/vim-sqlfmt'

Plug 'folke/trouble.nvim'
Plug 'navarasu/onedark.nvim'
Plug 'marko-cerovac/material.nvim'
Plug 'EdenEast/nightfox.nvim'
Plug 'pinecoders/vim-pine-script'

" Initialize plugin system
call plug#end()
" }}}
" Misc {{{
set ttyfast                     " faster redraw
set backspace=indent,eol,start
" }}}
" Searching {{{
set hlsearch
set incsearch
set ignorecase
set smartcase

map <CR> :nohl<cr>
" }}}
" Undo / Swap shit {{{
" http://stackoverflow.com/questions/4331776/change-vim-swap-backup-undo-file-name/9528322#9528322
" Save your backups to a less annoying place than the current directory.
" If you have .vim-backup in the current directory, it'll use that.
" Otherwise it saves it to ~/.nvim/backup or . if all else fails.
"
if isdirectory($HOME . '/.nvim/backup') == 0
  :silent !mkdir -p ~/.nvim/backup >/dev/null 2>&1
endif
set backupdir-=.
set backupdir-=./.nvim-backup/
set backupdir+=.
set backupdir-=~/
set backupdir^=~/.nvim/backup/
set backup

" Save your swp files to a less annoying place than the current directory.
" If you have .vim-swap in the current directory, it'll use that.
" Otherwise it saves it to ~/.nvim/swap, ~/tmp or .
if isdirectory($HOME . '/.nvim/swap') == 0
  :silent !mkdir -p ~/.nvim/swap >/dev/null 2>&1
endif
set directory=./.nvim-swap//
set directory+=~/.nvim/swap//
set directory+=~/tmp//
set directory+=.

" viminfo stores the the state of your previous editing session
set viminfo+=n~/.nvim/viminfo

if exists("+undofile")
  " undofile - This allows you to use undos after exiting and restarting
  " This, like swap and backups, uses .nvim-undo first, then ~/.nvim/undo
  " :help undo-persistence
  " I copied this from my vimrc, no idea if this is an issue in nvim
  if isdirectory($HOME . '/.nvim/undo') == 0
    :silent !mkdir -p ~/.nvim/undo > /dev/null 2>&1
  endif
  set undodir=./.nvim-undo//
  set undodir+=~/.nvim/undo//
  set undofile
endif
" }}}
" Mouse Shit {{{
set mouse=a                 " Automatically enable mouse usage
set mousehide               " Hide the mouse cursor while typing<Paste>
" }}}
" Tab and Space Shit {{{
" Set tabs to be not stupid "
set tabstop=2
set softtabstop=2
set expandtab
set shiftwidth=2

set nojoinspaces            " Prevents inserting two spaces after punctuation on a join (J)

autocmd FileType go setlocal noexpandtab
" }}}
" Commands {{{
command! MakeTags !ctags -R --exclude=_build .
set tags=tags;/
" }}}
" Leader Shortcuts {{{
let g:mapleader=','
noremap <leader>bg :call ToggleBG()<CR>
nnoremap <leader>rtw :%s/\s\+$//e<CR>
nmap <leader>pry orequire IEx; IEx.pry<esc>

"Quickfix Shortcuts
augroup QuickfixMappings
  autocmd!
  autocmd FileType qf nnoremap <buffer> <Leader>q :cclose<CR>
  autocmd FileType qf nnoremap <buffer> <leader>n :cnext<CR>
  autocmd FileType qf nnoremap <buffer> <leader>p :cprevious<CR>
  autocmd FileType qf nnoremap <buffer> <leader>f :cfirst<CR>
  autocmd FileType qf nnoremap <buffer> <leader>l :clast<CR>
augroup END
" }}}
" Folding {{{
set foldenable
set foldnestmax=10      " 10 nested fold max
set foldlevelstart=10   " open most folds by default
set foldmethod=indent
" space open/closes folds
nnoremap <space> za
" }}}
" Custom Functions {{{
function! ToggleBG()        " Allow to trigger background
  let s:tbg = &background
  if s:tbg == "dark"
    set background=light
  else
    set background=dark
  endif
endfunction

function! StripTrailingWhitespace()
    " Preparation save last search, and cursor position.
    let _s=@/
    let l = line(".")
    let c = col(".")
    " Do the business:
    %s/\s\+$//e
    " Clean up: restore previous search history, and cursor position
    let @/=_s
    call cursor(l, c)
endfunction
" }}}
" Formatting {{{
set nowrap                      " Do not wrap long lines
" Remove trailing whitespaces and ^M chars
autocmd FileType c,cpp,css,eelixir,elixir,groovy,heex,html,java,go,leex,liquid,lua,markdown,markdown.spec,php,purescript,javascript,jsx,json,pine,puppet,psl,python,rust,ruby,scss,sh,stylus,twig,xml,yml,perl,sql,md,ts,typescript,terraform,vcl,yml,yaml autocmd BufWritePre <buffer> call StripTrailingWhitespace()
"autocmd FileType go autocmd BufWritePre <buffer> Fmt
autocmd FileType haskell,puppet,purs,ruby,yml,javascript,elixir setlocal expandtab shiftwidth=2 softtabstop=2
" preceding line best in a plugin but here for now.

autocmd BufNewFile,BufRead *.html.twig set filetype=html.twig
autocmd BufNewFile,BufRead *.scerb set filetype=scss.erb
autocmd BufNewFile,BufRead *.coffee set filetype=coffee
autocmd BufNewFile,BufRead *.leex set filetype=eelixir
autocmd BufNewFile,BufRead .envrc set filetype=bash
autocmd BufRead,BufNewFile Appraisals set filetype=ruby

autocmd BufNewFile,BufRead */helm*/**/*.yaml set filetype=helm.yaml

" Workaround vim-commentary for Haskell
autocmd FileType haskell setlocal commentstring=--\ %s
" Workaround broken colour highlighting in Haskell
autocmd FileType haskell,rust setlocal nospell

" Syntax highlight for digdag files
au! BufNewFile,BufRead *.dig setfiletype yml

" Syntax highlight for spec gauge files
au! BufNewFile,BufRead *.spec setfiletype markdown
au! BufNewFile,BufRead *.spec if &ft == 'spec' | set ft=markdown | endif

" Syntax highlight for prettierrc gauge files
au! BufNewFile,BufRead .prettierrc setfiletype json

"Wrap for Markdown files
au FileType markdown setlocal textwidth=80

let g:NERDCustomDelimiters = { 'dosini': { 'left': '# ' } }

let g:rubycomplete_buffer_loading = 1

if did_filetype()
    finish
endif
if getline(1) =~# '^#!.*/bin/env\s\+[babel\-]?node\>'
    setfiletype javascript
endif

let g:jsx_ext_required = 0
" }}}
" UI Related Shit / Theme {{{
set splitright              " Puts new vsplit windows to the right of the current
set splitbelow              " Puts new split windows to the bottom of the current

set number                  " Set de nubmers
set relativenumber          " Set de relnubmers
set list listchars=tab:»·,trail:·

set laststatus=2

syntax enable
filetype plugin indent on   " Automatically detect file types.
set t_Co=256
set background=dark         " Assume a dark background
"colorscheme molokai
"colorscheme hybrid_reverse
"colorscheme solarized

"Neodark settings
"let g:neodark#background = '#5f5a63'
"let g:neodark#terminal_transparent = 1 " default: 0
"colorscheme neodark

"Material
"let g:material_style = 'Oceanic'
"let g:material_disable_background = 1
"colorscheme material

"OneDark
"let g:onedark_transparent_background = 1
"colorscheme onedark

"NightFox
"https://github.com/EdenEast/nightfox.nvim
"let g:nightfox_transparent = 1
"let g:nightfox_italic_keywords = 1
"let g:nightfox_style = nordfox
lua << EOF
local nightfox = require('nightfox')

-- This function set the configuration of nightfox. If a value is not passed in the setup function
-- it will be taken from the default configuration above
nightfox.setup({
  options = {
    fox = "dayfox",
    transparent = true,
    italic_keywords = true,
    terminal_colors = true,
    styles = {
        functions = "italic,bold" -- styles can be a comma separated list
    },
    inverse = {
        match_paren = true -- inverse the highlighting of match_parens
    },
    colors = {
        red = "#FFCCCB" -- Override the red color for MAX POWER
    }
  }
})
EOF
colorscheme nightfox



"Cursorline
set cursorline
let g:airline_theme = "bubblegum"
set colorcolumn=80
highlight CursorLine ctermbg=238 guibg=#444555
highlight ColorColumn ctermbg=238 guibg=#444555
" }}}
" Clipboard stuff {{{
" ------- Do some stupid shit w/ clipboard that
"  ------ I can't live without cause I suck
set clipboard=unnamed
if has('clipboard')
  if has('unnamedplus')  " When possible use + register for copy-paste
    set clipboard=unnamed,unnamedplus
  else         " On mac and Windows, use * register for copy-paste
    set clipboard=unnamed
  endif
endif
" }}}
" Autoclose {{{
" Force newline and put cursor in center
inoremap {<CR> {<CR>}<C-o>==<C-o>O
inoremap (<CR> (<CR>)<C-o>==<C-o>O
inoremap [<CR> [<CR>]<C-o>==<C-o>O
imap {{ {{}}<Esc>hi
" }}}
" EasyMotion {{{
let g:EasyMotion_keys ='abcdefghijklmnopqrstuvwxyz;'
" }}}
" Ctrl P {{{
set wildignore+=*/tmp/*,*.so,*.swp,*.zip,*.beam
let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git\|_build\|output\|dist\|build\|*.beam\~$'
let g:ctrlp_show_hidden = 1
" }}}
" NVimTree {{{
"let g:nvim_tree_width = 20

"nnoremap <C-e> :NvimTreeToggle<CR>
"nnoremap <S-r> :NvimTreeRefresh<CR>
"highlight NvimTreeFolderIcon guibg=transparent
" }}}
" NERDtree {{{
let g:NERDShutUp=1
nnoremap <C-e> :NERDTreeToggle<CR>
map <leader>e :NERDTreeFind<CR>
nmap <leader>nt :NERDTreeFind<CR>

let NERDTreeShowBookmarks=1
let NERDTreeIgnore=['\.py[cd]$', '\~$', '\.swo$', '\.swp$', '^\.git$', '^\.hg$', '^\.svn$', '\.bzr$']
let NERDTreeChDirMode=0
let NERDTreeMouseMode=0
let NERDTreeShowHidden=1
let NERDTreeQuitOnOpen=1
" }}}
" Undotree {{{
map <leader><leader>u :UndotreeToggle<CR>
" }}}
" Snippets {{{
" Elixir
nnoremap <leader>def :-1read $HOME/.vim.snippets/.elixir_def.exs<CR>eeb
nnoremap <leader>defp :-1read $HOME/.vim.snippets/.elixir_defp.exs<CR>eeb
nnoremap <leader>defm :-1read $HOME/.vim.snippets/.elixir_defmodule.exs<CR>eeb
nnoremap <leader>extest :-1read $HOME/.vim.snippets/.elixir_test.exs<CR>ee
nnoremap <leader>mdoc :-1read $HOME/.vim.snippets/.elixir_mdoc.exs<CR>j<Ctrl>i

" HTML
nnoremap <leader>div :-1read $HOME/.vim.snippets/.div.html<CR>eebl
nnoremap <leader>divwc :-1read $HOME/.vim.snippets/.div_with_class.html<CR>eeeh

" }}}
" Window Swap {{{
let g:windowswap_map_keys = 0 "prevent default bindings
nnoremap <silent> <leader>yw :call WindowSwap#MarkWindowSwap()<CR>
nnoremap <silent> <leader>pw :call WindowSwap#DoWindowSwap()<CR>
nnoremap <silent> <leader>ew :call WindowSwap#EasyWindowSwap()<CR>
" }}}
" Vim Obsession (underscores) {{{
"autocmd VimEnter * Obsess ~/.vim/sessions/
" }}}
" SQL Formatting {{{
let g:sqlfmt_command = "sqlfmt"
let g:sqlfmt_options = ""
" }}}
" LSPs setup {{{
lua << EOF
require("init")
EOF
" }}}
" vim:foldmethod=marker:foldlevel=0
