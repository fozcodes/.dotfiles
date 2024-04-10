## Meez dotfiles

Managed using [rcrc](http://thoughtbot.github.io/rcm)

Be sure to set the `RCRC` env var to point to the `.rcrc` file in this dir.

- needs to be full path. you can't use `~`

```
RCRC="<HOME_DIR>/.dotfiles/.rcrc" rcup
```

Also, make _sure_ that your subdirectories _aren't_ empty. Like for example, if you were experimenting with `git submodule` and deleted the contents. :facepalm:
