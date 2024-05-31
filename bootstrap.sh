#!/usr/bin/env bash

#install brew and brews
./install_brews.sh

#install asdf for package management
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.0

# install ruby
asdf plugin add ruby

# install erlang
asdf plugin add erlang

# install elixir
asdf plugin add elixir

# install node
asdf plugin add nodejs

# install terraform
asdf plugin add terraform

# install Lua
asdf plugin add lua

# install Python
asdf plugin add python

# install Poetry
asdf plugin add poetry


#install

# setup fonts
git clone git@github.com:powerline/fonts.git
./fonts/install.sh
rm -rf .fonts

# setup fish
echo "/opt/homebrew/bin/fish" | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
curl -L https://get.oh-my.fish | fish
omf install agnoster
omf theme agnoster

# install vundle
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
mkdirp ~/.vim/sessions

# copy rcm config
ln -s ~/.dotfiles/.rcrc ~/.rcrc
rcup

# setup ssh keys (You'll need to gen one...)
mkdir -p ~/.ssh
mv ./config/ssh/config ~/.ssh/config
ssh-keygen -t rsa -b 4096 -C "ian@codeguy.io"
ssh-add -K ~/.ssh/id_rsa
