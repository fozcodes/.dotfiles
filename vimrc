set nocompatible
filetype off

" http://stackoverflow.com/questions/4331776/change-vim-swap-backup-undo-file-name/9528322#9528322
" Save your backups to a less annoying place than the current directory.
" If you have .vim-backup in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/backup or . if all else fails.
if isdirectory($HOME . '/.vim/backup') == 0
  :silent !mkdir -p ~/.vim/backup >/dev/null 2>&1
endif
set backupdir-=.
set backupdir+=.
set backupdir-=~/
set backupdir^=~/.vim/backup/
set backupdir^=./.vim-backup/
set backup

" Save your swp files to a less annoying place than the current directory.
" If you have .vim-swap in the current directory, it'll use that.
" Otherwise it saves it to ~/.vim/swap, ~/tmp or .
if isdirectory($HOME . '/.vim/swap') == 0
  :silent !mkdir -p ~/.vim/swap >/dev/null 2>&1
endif
set directory=./.vim-swap//
set directory+=~/.vim/swap//
set directory+=~/tmp//
set directory+=.

" viminfo stores the the state of your previous editing session
set viminfo+=n~/.vim/viminfo

if exists("+undofile")
  " undofile - This allows you to use undos after exiting and restarting
  " This, like swap and backups, uses .vim-undo first, then ~/.vim/undo
  " :help undo-persistence
  " This is only present in 7.3+
  if isdirectory($HOME . '/.vim/undo') == 0
    :silent !mkdir -p ~/.vim/undo > /dev/null 2>&1
  endif
  set undodir=./.vim-undo//
  set undodir+=~/.vim/undo//
  set undofile
endif

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'

Plugin 'AutoClose'
Plugin 'ctrlp.vim'
Plugin 'easymotion/vim-easymotion'
Plugin 'elixir-lang/vim-elixir'
Plugin 'elzr/vim-json'
Plugin 'isRuslan/vim-es6'
Plugin 'mbbill/undotree'
Plugin 'roman/golden-ratio'
Plugin 'scrooloose/nerdcommenter'
Plugin 'scrooloose/nerdtree.git'
Plugin 'scrooloose/syntastic'
Plugin 'Shougo/neocomplete.vim.git'
Plugin 'Shougo/neosnippet'
Plugin 'Shougo/neosnippet-snippets'
Plugin 'honza/vim-snippets'
Plugin 'tpope/vim-markdown'
Plugin 'tpope/vim-rails'
Plugin 'tpope/vim-surround'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'w0ng/vim-hybrid'

" All of your Plugins must be added before the following line
call vundle#end()            " required

if filereadable(glob("~/.vimrc.local"))
  source ~/.vimrc.local
endif

for f in split(glob('~/.vimrc.plugins.config/*.vim'), '\n')
  exe 'source' f
endfor

let g:ctrlp_custom_ignore = 'node_modules\|DS_Store\|git\|\~$'


" --------------- NERDtree has to be in .vimrc too....? -------
let g:NERDShutUp=1
nnoremap <C-e> :NERDTreeToggle<CR>
map <leader>e :NERDTreeFind<CR>
nmap <leader>nt :NERDTreeFind<CR>

let NERDTreeShowBookmarks=1
let NERDTreeIgnore=['\.py[cd]$', '\~$', '\.swo$', '\.swp$', '^\.git$', '^\.hg$', '^\.svn$', '\.bzr$']
let NERDTreeChDirMode=0
let NERDTreeQuitOnOpen=1
let NERDTreeMouseMode=2
let NERDTreeShowHidden=1
let NERDTreeKeepTreeInNewTab=1
let g:nerdtree_tabs_open_on_gui_startup=0

" --------------- NEOCOMPLETE - has to be IN .vimrc...? (angry face)------
let g:neocomplete#enable_at_startup = 1
if has("autocmd") && exists("+omnifunc")
  autocmd Filetype *
        \if &omnifunc == "" |
        \setlocal omnifunc=syntaxcomplete#Complete |
        \endif
endif

" Some convenient mappings
inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
inoremap <expr> <C-d>      pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
inoremap <expr> <C-u>      pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"

" Automatically open and close the popup menu / preview window
au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
set completeopt=menu,preview,longest

let g:acp_enableatstartup = 1
let g:neocomplete#enable_smart_case = 1
let g:neocomplete#enable_auto_delimiter = 1
let g:neocomplete#max_list = 15
let g:neocomplete#force_overwrite_completefunc = 1

" define dictionary.
let g:neocomplete#sources#dictionary#dictionaries = {
      \ 'default' : '',
      \ 'vimshell' : $home.'/.vimshell_hist',
      \ 'scheme' : $home.'/.gosh_completions'
      \ }

" define keyword.
if !exists('g:neocomplete#keyword_patterns')
  let g:neocomplete#keyword_patterns = {}
endif
let g:neocomplete#keyword_patterns['default'] = '\h\w*'

" these two lines conflict with the default digraph mapping of <c-k>
imap <c-k> <plug>(neosnippet_expand_or_jump)
smap <c-k> <plug>(neosnippet_expand_or_jump)

inoremap <cr> <cr>
" <esc> takes you out of insert mode
inoremap <expr> <esc>   pumvisible() ? "\<c-y>\<esc>" : "\<esc>"
" <cr> accepts first, then sends the <cr>
inoremap <expr> <cr>    pumvisible() ? "\<c-y>\<cr>" : "\<cr>"
" <down> and <up> cycle like <tab> and <s-tab>
inoremap <expr> <down>  pumvisible() ? "\<c-n>" : "\<down>"
inoremap <expr> <up>    pumvisible() ? "\<c-p>" : "\<up>"
" jump up and down the list
inoremap <expr> <c-d>   pumvisible() ? "\<pagedown>\<c-p>\<c-n>" : "\<c-d>"
inoremap <expr> <c-u>   pumvisible() ? "\<pageup>\<c-p>\<c-n>" : "\<c-u>"
" <c-k> complete snippet
" <c-k> jump to next snippet point
imap <silent><expr><c-k> neosnippet#expandable() ?
      \ "\<plug>(neosnippet_expand_or_jump)" : (pumvisible() ?
      \ "\<c-e>" : "\<plug>(neosnippet_expand_or_jump)")
smap <tab> <right><plug>(neosnippet_jump_or_expand)

inoremap <expr><c-g> neocomplete#undo_completion()
inoremap <expr><c-l> neocomplete#complete_common_string()
"inoremap <expr><cr> neocomplete#complete_common_string()

" <cr>: close popup
" <s-cr>: close popup and save indent.
inoremap <expr><s-cr> pumvisible() ? neocomplete#smart_close_popup()."\<cr>" : "\<cr>"

function! CleverCr()
  if pumvisible()
    return "\<esc>a"
  else
    return "\<Enter>"
  endif
endfunction

" <cr> close popup and save indent or expand snippet
imap <expr> <CR> CleverCr()
" <c-h>, <bs>: close popup and delete backword char.
inoremap <expr><bs> neocomplete#smart_close_popup()."\<c-h>"
inoremap <expr><c-y> neocomplete#smart_close_popup()
" <TAB>: completion.
inoremap <expr><TAB> pumvisible() ? "\<C-n>" : "\<TAB>"
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<TAB>"

" courtesy of matteo cavalleri

function! Clevertab()
  if pumvisible()
    return "\<c-n>"
  endif
  let substr = strpart(getline('.'), 0, col('.') - 1)
  let substr = matchstr(substr, '[^ \t]*$')
  if strlen(substr) == 0
    " nothing to match on empty string
    return "\<tab>"
  else
    " existing text matching
    if neosnippet#expandable_or_jumpable()
      return "\<plug>(neosnippet_expand_or_jump)"
    else
      return neocomplete#start_manual_complete()
    endif
  endif
endfunction

imap <expr> <tab> Clevertab()

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc

" enable heavy omni completion.
if !exists('g:neocomplete#sources#omni#input_patterns')
  let g:neocomplete#sources#omni#input_patterns = {}
endif
let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.perl = '\h\w*->\h\w*\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.c = '[^.[:digit:] *\t]\%(\.\|->\)'
let g:neocomplete#sources#omni#input_patterns.cpp = '[^.[:digit:] *\t]\%(\.\|->\)\|\h\w*::'
let g:neocomplete#sources#omni#input_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'

" use honza's snippets.
let g:neosnippet#snippets_directory='~/.vim/bundle/vim-snippets/snippets'

" enable neosnippet snipmate compatibility mode
let g:neosnippet#enable_snipmate_compatibility = 1

" for snippet_complete marker.
if has('conceal')
  set conceallevel=2 concealcursor=i
endif

" enable neosnippets when using go
let g:go_snippet_engine = "neosnippet"

" disable the neosnippet preview candidate window
" when enabled, there can be too much visual noise
" especially when splits are used.
set completeopt-=preview
" -------------- END NEOCOMPLETE --------------------------

" -------------------- Trailing Whitespace --------------
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
