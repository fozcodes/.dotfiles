#!/usr/bin/env bash

# install Homebrew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update
#install cask
brew tap caskroom/cask

# install me brews -  the obscure ones are probably for asdf
brew install 1password
brew install 1password-cli
brew install adns
brew install ansible
brew install aom
brew install atomicparsley
brew install autoconf
brew install automake
brew install aws-elasticbeanstalk
brew install aws-iam-authenticator
brew install awscli
brew install bash-completion
brew install bat
brew install battery
brew install bdw-gc
brew install berkeley-db
brew install brotli
brew install c-ares
brew install cairo
brew install circleci
brew install cmake
brew install cocoapods
brew install cscope
brew install dav1d
brew install direnv
brew install docbook
brew install docbook-xsl
brew install efm-langserver
brew install exercism
brew install ffmpeg
brew install fish
brew install flac
brew install fontconfig
brew install freetype
brew install frei0r
brew install fribidi
brew install fzf
brew install gd
brew install gdbm
brew install gdk-pixbuf
brew install gettext
brew install gh
brew install ghostscript
brew install giflib
brew install git
brew install git-filter-repo
brew install glib
brew install gmp
brew install gnu-getopt
brew install gnu-sed
brew install gnupg
brew install gnutls
brew install go
brew install gobject-introspection
brew install graphite2
brew install graphviz
brew install grip
brew install gts
brew install guile
brew install harfbuzz
brew install heroku
brew install heroku-node
brew install htop
brew install hub
brew install icu4c
brew install ilmbase
brew install imagemagick
brew install imath
brew install jasper
brew install jemalloc
brew install jpeg
brew install jq
brew install krb5
brew install lame
brew install lazydocker
brew install leiningen
brew install leptonica
brew install libass
brew install libassuan
brew install libbluray
brew install libde265
brew install libev
brew install libevent
brew install libffi
brew install libgcrypt
brew install libgpg-error
brew install libheif
brew install libidn2
brew install libksba
brew install liblqr
brew install libnet
brew install libogg
brew install libomp
brew install libpng
brew install libpthread-stubs
brew install libressl
brew install librsvg
brew install libsamplerate
brew install libsndfile
brew install libsodium
brew install libsoxr
brew install libssh
brew install libtasn1
brew install libtermkey
brew install libtiff
brew install libtool
brew install libunistring
brew install libusb
brew install libuv
brew install libvidstab
brew install libvorbis
brew install libvpx
brew install libvterm
brew install libx11
brew install libxau
brew install libxcb
brew install libxdmcp
brew install libxext
brew install libxml2
brew install libxrender
brew install libxslt
brew install libyaml
brew install libzip
brew install little-cms2
brew install lsd
brew install lua
brew install luajit-openresty
brew install luv
brew install lzo
brew install m4
brew install mas
brew install mpdecimal
brew install msgpack
brew install ncurses
brew install neovim
brew install netpbm
brew install nettle
brew install nghttp2
brew install node
brew install npth
brew install oniguruma
brew install openconnect
brew install opencore-amr
brew install openexr
brew install openjdk
brew install openjdk@11
brew install openjpeg
brew install openssl@1.1
brew install opus
brew install p11-kit
brew install pango
brew install pcre
brew install pcre2
brew install peco
brew install perl
brew install pinentry
brew install pixman
brew install pkg-config
brew install postgresql
brew install pyenv
brew install pyenv-virtualenv
brew install pyright
brew install rav1e
brew install rcm
brew install readline
brew install reattach-to-user-namespace
brew install ripgrep
brew install rtmpdump
brew install rubberband
brew install ruby
brew install sdl2
brew install serverless
brew install shared-mime-info
brew install siege
brew install snappy
brew install spark
brew install speex
brew install sqlite
brew install srt
brew install starship
brew install stoken
brew install tcl-tk
brew install tcptraceroute
brew install telnet
brew install tesseract
brew install themekit
brew install theora
brew install tidy-html5
brew install tldr
brew install tmate
brew install tmux
brew install tree
brew install tree-sitter
brew install truncate
brew install unbound
brew install unibilium
brew install universal-ctags
brew install unixodbc
brew install utf8proc
brew install vim
brew install webp
brew install wget
brew install wxmac -> wxwidgets
brew install wxwidgets
brew install x264
brew install x265
brew install xmlto
brew install xorgproto
brew install xvid
brew install xz
brew install yarn
brew install zeromq
brew install zimg
brew install abstract
brew install adobe-acrobat-reader
brew install airtable
brew install alacritty
brew install brave-browser
brew install chromedriver
brew install controlplane
brew install dash
brew install discord
brew install docker
brew install emacs
brew install fantastical
brew install firefox
brew install flux
brew install font-hack-nerd-font
brew install font-iosevka
brew install front
brew install google-chrome
brew install google-cloud-sdk
brew install google-drive-file-stream
brew install graphiql
brew install insomnia
brew install intellij-idea-ce
brew install iterm2
brew install java
brew install keybase
brew install keycastr
brew install kindle
brew install licecap
brew install macdown
brew install microsoft-teams
brew install ngrok
brew install paw
brew install postgres
brew install postico
brew install postman
brew install protonvpn
brew install send-to-kindle
brew install sequel-pro
brew install signal
brew install sketch
brew install slack
brew install spotify
brew install sqlpro-studio
brew install steam
brew install stretchly
brew install sublime-text
brew install tableplus
brew install thinkorswim
brew install vagrant
brew install visual-studio-code
brew install vlc
brew install whatsapp
brew install zeplin
brew install zsa-wally

# install ctags after emacs
brew install --HEAD universal-ctags/universal-ctags/universal-ctags
brew link --overwrite universal-ctags
