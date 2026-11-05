# Dotfiles

This repository is the managed source for a personal computing environment. Its language distinguishes live configuration, private state, platform branches, and the programs that consume configuration.

## Configuration

**Managed configuration**:
Tracked configuration whose deployed home path is an rcm-managed live symlink to this repository.
_Avoid_: copied configuration, deployed copy

**Deployment reconciliation**:
The rcm operation that creates or removes managed links after the managed file set changes.
_Avoid_: ordinary edit, configuration reload

**Repository-only documentation**:
Tracked documentation that explains this repository but does not deploy into the home environment.
_Avoid_: managed configuration

**Configuration consumer**:
The program that reads a configuration domain and therefore owns its behavior.
_Avoid_: repository owner, file owner

## Portability and boundaries

**Platform branch**:
A branch whose configuration targets one operating-system environment. macOS and Linux use separate platform branches.
_Avoid_: universal configuration

**Private local state**:
Credentials, personal machine paths, and runtime or user-specific data that stays outside tracked configuration.
_Avoid_: managed configuration, shared state

**Vendor dependency**:
Pinned external source, including a submodule, that remains unchanged unless its modification or revision update is requested.
_Avoid_: local configuration
