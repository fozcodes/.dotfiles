###### IMPORTANT - Remember files in ./conf.d are loaded automagically #########
function fish_right_prompt
  set_color $fish_color_autosuggestion; or set_color 555
  date "+%H:%M:%S"
  set_color normal
end

set BREW_HOME (brew --prefix)

fish_add_path $HOME/.asdf/shims
fish_add_path $BREW_HOME/bin

# ASDF
source $HOME/.asdf/asdf.fish
source $HOME/.asdf/completions/asdf.fish


set PATH /usr/local/opt/make/libexec/gnubin $PATH
set PATH /usr/local/opt/findutils/libexec/gnubin $PATH


# aliases

alias brow='arch --x86_64 /usr/local/Homebrew/bin/brew'

alias b="bundle"
alias be="bundle exec"
alias c="clear"
alias dkrmall="docker rm (docker ps -a -q)"
alias gaac="git add .; and git commit"
alias gitcleanbranchesmaster="git branch --merged | grep -v master | xargs git branch -D"
alias gitcleanbranches="git branch --merged | grep -v main | xargs git branch -D"
alias gitreallycleanbranches="git branch | grep -v 'main' | xargs git branch -D"
alias grb="git rebase -i origin/main"
alias grbmaster="git rebase -i origin/master"
alias grbc="git rebase --continue"
alias grep="grep --color --exclude=\"*/coverage/*\" --exclude=\"*.git/*\""
alias la="lsd -la"
alias mkdir="mkdir -p"
alias npmi="npm install"
alias rcup="env RCRC=~/.dotfiles/.rcrc rcup"
alias rst="touch tmp/restart.txt"
alias subl="/Applications/Sublime\ Text.app/Contents/SharedSupport/bin/subl"
alias tl="tmux ls"
alias nvimk='NVIM_APPNAME="nvim-kickstart" nvim'

# Snowflake cli
fish_add_path /Applications/SnowSQL.app/Contents/MacOS/

# functions
function mkdircd
  mkdir -p $argv; and cd $argv
end

function npms
  npm install -SE $argv
end

function npmsd
  npm install --save-dev -E $argv
end

function mixnew
  mix new $argv; and cd $argv
end

function phnew
  mix phoenix.new $argv; and cd $argv
end

function find_up
  set -l filename $argv
  set -l cwd (pwd)
  set -l dir (pwd)

  while not test "$dir" != '/'
    set version_file "$dir/$filename"

    if test -f "$version_file"
      echo $version_file; and break
    end

    builtin cd $dir/..
    set dir (pwd)
  end
  builtin cd $cwd
end

function save_your_damn_notes
  cd ~/Code/notes 
  git add .
  git commit -m "autosaving..."
  git push origin master
end

set -x FZF_DEFAULT_OPTS "--height 50% --reverse --preview 'bat --style=numbers --color=always --line-range :500 {}'"
set -x FZF_DEFAULT_COMMAND "rg --files"

# set iex/erlang history var
set -Ux ERL_AFLAGS "-kernel shell_history enabled"

# starship
if type -q starship
  starship init fish | source
end

direnv hook fish | source

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[ -f /Users/foz/.asdf/installs/nodejs/8.9.4/.npm/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.fish ]; and . /Users/foz/.asdf/installs/nodejs/8.9.4/.npm/lib/node_modules/serverless/node_modules/tabtab/.completions/serverless.fish
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[ -f /Users/foz/.asdf/installs/nodejs/8.9.4/.npm/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.fish ]; and . /Users/foz/.asdf/installs/nodejs/8.9.4/.npm/lib/node_modules/serverless/node_modules/tabtab/.completions/sls.fish

# Ooof. SSL issues.
set -g fish_user_paths "$BREW_HOME/opt/libressl/bin" "/Users/foz/.bin" $fish_user_paths

set -g -x "CLOUDSDK_PYTHON" "$BREW_HOME/opt/python@3.9/libexec/bin/python"
source "$BREW_HOME/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.fish.inc"

thefuck --alias | source
