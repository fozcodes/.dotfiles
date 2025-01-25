###### IMPORTANT - Remember files in ./conf.d are loaded automagically #########
function fish_right_prompt
  set -l fish_color_autosuggestion
  set_color $fish_color_autosuggestion; or set_color 555
  date "+%H:%M:%S"
  set_color normal
end

eval "$(/opt/homebrew/bin/brew shellenv)"

set PATH /usr/local/opt/make/libexec/gnubin $PATH
set PATH /usr/local/opt/findutils/libexec/gnubin $PATH
set PATH /opt/homebrew/opt/postgresql@14/bin $PATH

set BREW_HOME (brew --prefix)

fish_add_path -p $BREW_HOME/opt/postgresql@16/bin
fish_add_path -p $BREW_HOME/bin
fish_add_path -p $HOME/.asdf/shims

# ASDF
source $HOME/.asdf/asdf.fish
source $HOME/.asdf/completions/asdf.fish

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
alias nvimold='NVIM_APPNAME="nvim-old" nvim'
function nvim
    env SHELL=/bin/bash command nvim $argv
end
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
  git pull --rebase 
  git push origin master
end

function get-k8s-namespaces
  kubectl get namespaces -o json | jq -r '.items[].metadata.name'
end

function get-k8s-secret-names
  argparse 'n/namespace=' 's/secret=' -- $argv
  or return

  if not set -q _flag_namespace
    echo "Namespace not specified. Use -n or --namespace to specify the namespace."
    return 1
  end

  kubectl --namespace $_flag_namespace get pods -o json \
      | jq -r '.items[].spec.containers[].env[]?.valueFrom.secretKeyRef.name' \
      | grep -v null \
      | sort \
      | uniq
end

function get-k8s-secret-in-namespace
  argparse 'n/namespace=' 's/secret=' -- $argv
  or return

  if not set -q _flag_namespace
    echo "Namespace not specified. Use -n or --namespace to specify the namespace."
    return 1
  end
  
  if not set -q _flag_secret
    echo "Secret name not specified. Use -s or --secret to specify the namespace."
    return 1
  end

  kubectl -n "$_flag_namespace" get secret "$_flag_secret"  \
    -o go-template='{{range $k,$v := .data}}{{"### "}}{{$k}}{{"\n"}}{{$v|base64decode}}{{"\n\n"}}{{end}}' \
    2>/dev/null
end

function select-k8s-namespace
    set -l available_namespaces (get-k8s-namespaces)
    echo $available_namespaces
    echo "Please choose a namespace:"
    for index in (seq (count $available_namespaces))
      echo "$index. $available_namespaces[$index]"
    end
    echo "Pick a number: "
    read choice

    if test "$choice" -gt 0 -a "$choice" -le (count $available_namespaces)
      set selected_namespace $available_namespaces[$choice]
      echo $selected_namespace
    else
      echo "Invalid choice. Please try again."
    end
end

function select-k8s-secret
  argparse 'n/namespace=' -- $argv
  or return
  
  if set -q _flag_namespace
    set ns $_flag_namespace
    echo "Showing secrets in: $ns"
    set -l available_secrets (get-k8s-secret-names -n $ns)
    echo $available_secrets
    echo "Please choose a secret:"

    for index in (seq (count $available_secrets))
      echo "$index. $available_secrets[$index]"
    end
    read choice

    if test "$choice" -gt 0 -a "$choice" -le (count $available_secrets)
      set selected_secret $available_secrets[$choice]
      echo $selected_secret
    else
      echo "Invalid choice. Please try again."
      return 1
    end
  else
    echo "You need to pass a namespace with -n or --namespace=, please try again."
    return 1
  end
end

function show-k8s-secrets
  argparse 'h/help' 'n/namespace=' -- $argv
  or return
  
  if set -q _flag_help
    echo "Usage: show-k8s-secrets [-h|--help] [-n|--namespace NAMESPACE]"
    echo "Options:"
    echo "  -h, --help             Show this help message and exit"
    echo "  -n, --namespace        Specify the namespace to show secrets for"
    return
  end
 
  if set -q _flag_namespace
    set -l selected_namespace $_flag_namespace 
    set -l selected_secret (select-k8s-secret -n $selected_namespace)
  else
    set -l selected_namespace (select-k8s-namespace)
  end

  get-k8s-secrets-in-namespace -n $_flag_namespace -s $selected_secret
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
