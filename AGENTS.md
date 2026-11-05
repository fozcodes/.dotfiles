# Dotfiles Repository Guidance

This file governs changes in this repository. It does not govern separately deployed Claude, Pi, or OpenCode instructions.

## Configuration model

- rcm-managed configuration is live through symlinks. The tracked source and its existing deployed path name the same configuration.
- Run `rcup` only after adding or removing a managed file, and only with user approval.
- Treat the current branch as the platform contract. macOS and Linux use separate branches.
- Derive paths from `$HOME`, the active tool, or runtime discovery. Never commit credentials or personal machine paths.
- Report existing path or secret violations when encountered. Leave unrelated cleanup for a separate request.

## Changes

- Make the smallest local change that preserves the consumer's conventions.
- Place cross-cutting tool rules here. Keep tool operation and syntax beside the consumer.
- Preserve pinned and vendored dependencies unless the user requests a modification or revision update.
- Preserve unrelated working-tree changes. Do not reset, restore, rebase, or amend them without approval.
- Ask before deployment, bootstrap, installation, system configuration, credential actions, or network-mutating commands.

## Completion

- Validate with the owning tool's check or syntax command when available. State when safe validation is unavailable.
- Commit small, verified changes by default.
- Update [CONTEXT.md](./CONTEXT.md) only when a stable term or boundary changes.
