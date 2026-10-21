# Agent Picker

A local Herdr plugin that opens an agent-only fuzzy picker. It lists every
agent in the current session, orders blocked and done agents first, supports
fzf filtering, and focuses the selected agent's exact pane on Enter.

`bootstrap-herdr.sh` links this plugin. The dotfiles bind it to `Ctrl-s s`.

## Requirements

- Herdr 0.8 or later
- `fzf`
- Unix-domain `nc` (`nc -U`)

## Verify

```sh
bash test/run.sh
```
