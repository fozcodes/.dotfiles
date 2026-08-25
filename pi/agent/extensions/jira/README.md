# Jira Cloud extension

Pi extension for Jira Cloud REST API v3. It uses no Jira CLI.

## Install

This directory is globally auto-discovered by Pi:

```text
~/.pi/agent/extensions/jira/
```

Restart Pi or run `/reload` after changes.

## Global connection and authentication

Run `/jira-setup`, then select **Global Jira Cloud connection and authentication**. Existing global values are offered as a one-click default. It writes non-secret global configuration:

```json
// ~/.pi/agent/jira.json
{
  "siteUrl": "https://company.atlassian.net",
  "email": "you@company.com"
}
```

`/jira-setup` offers to open the [Atlassian API-token page](https://id.atlassian.com/manage-profile/security/api-tokens), which uses your normal Atlassian/SSO login. Pi then prompts for the copied token without restarting setup, writes it to `~/.pi/agent/jira.json` with file mode `0600`, and verifies it with Jira.

The global configuration file is outside repositories and must never be committed or shared.

## Repository routing

In each trusted repository, run `/jira-setup`, then select **This repository's default Jira project**. An existing `defaultProjectKey` is offered as a one-click default. `/jira-project ABC` remains an equivalent direct command.

This writes a non-secret project-local config:

```json
// <repo>/.pi/jira.json
{
  "defaultProjectKey": "ABC"
}
```

Commit it when teammates should share the routing rule. There is deliberately no global default Jira project.

If a project has no config and Pi needs one for a scoped operation, it asks before creating this file. An untrusted repository cannot read or write its `.pi/jira.json`.

Pass `projectKey` to `jira_search`, `jira_create`, or `jira_create_metadata` for an explicit per-request override. Searches are JQL-scoped and response-filtered to that selected project. Issue keys identify their project for `jira_get`, `jira_update`, `jira_transition`, and `jira_comment`; those write confirmations display the target project.

## Tools

Read-only:

- `jira_search`
- `jira_get`
- `jira_create_metadata`
- `jira_assignable_users`
- `jira_transitions`

Writes, each with an interactive confirmation. Confirmations are serialized, so a parallel tool batch presents one dialog at a time; Escape cancels the active confirmation and prevents queued writes from reaching Jira.

- `jira_create`
- `jira_update`
- `jira_transition`
- `jira_comment`

In print/JSON modes write tools refuse to run because no human confirmation is possible.

## Writing

`jira_create` and `jira_update` accept an optional `parent` issue key (for example, `ABC-123`) and write it to Jira's `fields.parent`. The extension validates the key and shows the parent in its mutation confirmation.

To assign a user, first call `jira_assignable_users` with their name or email and the relevant project or issue. Pass its `accountId` result as `assigneeAccountId` to `jira_create` or `jira_update`. Jira Cloud requires account IDs; assignment appears in the mutation confirmation.

The extension preserves supplied summary, description, and comment text. Your repository context, examples, and instructions determine project conventions and voice. Jira descriptions and comments are sent as Atlassian Document Format paragraphs.

Before creating an issue in an unfamiliar project, use `jira_create_metadata` to discover permitted issue types.
