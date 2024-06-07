#!/usr/bin/env bash

if ! command -v brew &> /dev/null
then
  # install Homebrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/foz/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update

brew bundle
