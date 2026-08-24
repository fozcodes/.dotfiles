## Meez dotfiles

Managed using [rcrc](http://thoughtbot.github.io/rcm)

Be sure to set the `RCRC` env var to point to the `.rcrc` file in this dir.

- needs to be full path. you can't use `~`

```bash
$ RCRC="<HOME_DIR>/.dotfiles/.rcrc" rcup
```

Also, make _sure_ that your subdirectories _aren't_ empty. Like for example, if
you were experimenting with `git submodule` and deleted the contents. :facepalm:

### Herdr

`vim-herdr-navigation` is pinned as a Git submodule under
`config/herdr/vendor/`, which deploys to `~/.config/herdr/vendor/`. After
installing Herdr and jq, initialize and link it with:

```sh
git submodule update --init --recursive
./bootstrap-herdr.sh
```

The script is also called by `bootstrap.sh` when `herdr` is available. Herdr
keybindings live in `config/herdr/config.toml`; Neovim loads the editor side
from the pinned submodule.
