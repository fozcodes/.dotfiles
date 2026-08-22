import { spawn } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import {
	DEFAULT_SEARCH_FIELDS,
	basicAuthorization,
	createAsyncQueue,
	excerpt,
	normalizeIssueKey,
	normalizeProjectKey,
	parentIssueField,
	normalizeSiteUrl,
	projectFromIssueKey,
	readGlobalConfig,
	restrictSearchResults,
	readRepoConfig,
	scopedJql,
	textToAdf,
	writeGlobalConfig,
	writeRepoConfig,
} from "./jira.ts";

const textResult = (text: string, details: Record<string, unknown> = {}) => ({
	content: [{ type: "text" as const, text }],
	details,
});

const errorResult = (error: unknown) => {
	const message = error instanceof Error ? error.message : "Unexpected Jira extension error.";
	return {
		...textResult(`Jira error: ${message}`, { error: message }),
		isError: true,
	};
};

const formatJson = (value: unknown) => JSON.stringify(value, undefined, "\t") ?? String(value);

const jiraRequest = async (
	path: string,
	options: Readonly<{
		method?: "GET" | "POST" | "PUT";
		body?: Record<string, unknown>;
		signal?: AbortSignal;
	}>,
) => {
	const config = await readGlobalConfig();
	if (!config.token) {
		throw new Error("Jira API token missing from ~/.pi/agent/jira.json. Run /jira-setup to add one.");
	}
	const token = config.token;
	const response = await fetch(`${normalizeSiteUrl(config.siteUrl)}/rest/api/3${path}`, {
		method: options.method ?? "GET",
		headers: {
			Accept: "application/json",
			Authorization: basicAuthorization(config.email, token),
			...(options.body ? { "Content-Type": "application/json" } : {}),
		},
		...(options.body ? { body: JSON.stringify(options.body) } : {}),
		signal: options.signal,
	});
	const text = await response.text();
	const body = text ? (() => {
		try {
			return JSON.parse(text) as unknown;
		} catch {
			return text;
		}
	})() : undefined;

	if (!response.ok) {
		if (response.status === 401) {
			throw new Error("Jira rejected the stored API token. Run /jira-setup to replace it.");
		}
		const detail = typeof body === "string" ? body : formatJson(body);
		throw new Error(`Jira ${response.status} ${response.statusText}: ${excerpt(detail, 1_000)}`);
	}
	return body;
};

const configureRepoProject = async (ctx: ExtensionContext) => {
	if (!ctx.isProjectTrusted()) {
		throw new Error("Refusing to read or write .pi/jira.json in an untrusted project.");
	}
	if (!ctx.hasUI) {
		throw new Error("This repository has no Jira project. Run /jira-project <KEY> interactively.");
	}
	const existing = await readRepoConfig(ctx.cwd);
	if (existing) {
		const choice = await ctx.ui.select("Repository Jira project", [
			`Use existing default: ${existing.defaultProjectKey}`,
			"Set a different default project",
		]);
		if (!choice) throw new Error("Repository Jira configuration was cancelled.");
		if (choice.startsWith("Use existing")) return existing.defaultProjectKey;
	}
	const approved = await ctx.ui.confirm(
		"Configure Jira project?",
		`Set the default Jira project for:\n${ctx.cwd}?`,
	);
	if (!approved) {
		throw new Error("Repository Jira configuration was cancelled.");
	}
	const input = await ctx.ui.input("Default Jira project key", existing?.defaultProjectKey ?? "For example: ABC");
	if (!input) {
		throw new Error("Repository Jira configuration was cancelled.");
	}
	const defaultProjectKey = normalizeProjectKey(input);
	await writeRepoConfig(ctx.cwd, { defaultProjectKey });
	ctx.ui.notify(`Jira default project: ${defaultProjectKey}`, "info");
	return defaultProjectKey;
};

const resolveProject = async (ctx: ExtensionContext, projectKey?: string) => {
	if (projectKey) return normalizeProjectKey(projectKey);
	if (!ctx.isProjectTrusted()) {
		throw new Error("An explicit Jira project key is required in an untrusted project.");
	}
	const config = await readRepoConfig(ctx.cwd);
	return config?.defaultProjectKey ?? configureRepoProject(ctx);
};

const confirmMutation = async (ctx: ExtensionContext, title: string, detail: string, signal?: AbortSignal) => {
	if (!ctx.hasUI) {
		throw new Error("Jira writes require interactive confirmation.");
	}
	return ctx.ui.confirm(title, detail, { signal });
};

const mutationProject = (issueKey: string, projectKey?: string) => {
	const issueProject = projectFromIssueKey(issueKey);
	if (projectKey && normalizeProjectKey(projectKey) !== issueProject) {
		throw new Error(`Issue ${issueKey} belongs to ${issueProject}, not ${normalizeProjectKey(projectKey)}.`);
	}
	return issueProject;
};

const issueFields = Type.Array(Type.String(), { description: "Jira field names to return." });
const optionalProject = Type.Optional(Type.String({ description: "Explicit Jira project key. Overrides this repository's default." }));
const optionalIssueProject = Type.Optional(Type.String({ description: "Optional safety check: must match the issue key's project." }));

export default function (pi: ExtensionAPI) {
	const queueMutation = createAsyncQueue();

	pi.on("before_agent_start", async (event) => {
		if (!/\b(jira|tickets?|kanban)\b/i.test(event.prompt)) return;
		const config = await readGlobalConfig().catch(() => undefined);
		const jiraInstruction = config?.token
			? "Jira authentication is configured. For Jira, ticket, or Kanban requests, call the relevant jira_* tool. Do not claim authentication is missing without a Jira tool result."
			: "Jira authentication is not configured. Tell the user to run /jira-setup; do not imply that a Jira query was attempted.";
		return { systemPrompt: `${event.systemPrompt}\n\n${jiraInstruction}` };
	});

	pi.registerCommand("jira-setup", {
		description: "Configure global Jira Cloud auth or this repository's default project",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("jira-setup requires interactive mode", "error");
				return;
			}
			const target = await ctx.ui.select("Jira setup", [
				"Global Jira Cloud connection and authentication",
				"This repository's default Jira project",
			]);
			if (!target) return;
			if (target === "This repository's default Jira project") {
				try {
					await configureRepoProject(ctx);
				} catch (error) {
					ctx.ui.notify(error instanceof Error ? error.message : "Unable to save Jira project.", "error");
				}
				return;
			}
			const existing = await readGlobalConfig().catch(() => undefined);
			const useExisting = existing && await ctx.ui.select("Jira Cloud connection", [
				`Use existing: ${existing.siteUrl} (${existing.email})`,
				"Change Jira site URL or account email",
			]);
			if (existing && !useExisting) return;
			const siteInput = useExisting?.startsWith("Use existing")
				? existing!.siteUrl
				: await ctx.ui.input("Jira Cloud site URL", existing?.siteUrl ?? "https://company.atlassian.net");
			if (!siteInput) return;
			const email = useExisting?.startsWith("Use existing")
				? existing!.email
				: await ctx.ui.input("Atlassian account email", existing?.email ?? "you@company.com");
			if (!email) return;
			try {
				const siteUrl = normalizeSiteUrl(siteInput);
				const accountEmail = email.trim();
				if (!accountEmail) throw new Error("Atlassian account email is required.");
				const canUseSavedToken = existing?.token && existing.siteUrl === siteUrl && existing.email === accountEmail;
				const tokenAction = await ctx.ui.select("Atlassian API token", [
					...(canUseSavedToken ? ["Use saved API token"] : []),
					"Paste an API token",
					"Open the Atlassian API-token page, then paste a token",
				]);
				if (!tokenAction) return;
				if (tokenAction.startsWith("Open")) {
					spawn("open", ["https://id.atlassian.com/manage-profile/security/api-tokens"], { stdio: "ignore", detached: true }).unref();
				}
				const token = tokenAction === "Use saved API token"
					? existing!.token!
					: (await ctx.ui.input("Jira API token", "Paste the token here after creating it in your browser."))?.trim();
				if (!token || token.includes("\n")) return;
				await writeGlobalConfig({ siteUrl, email: accountEmail, token });
				await jiraRequest("/myself", {});
				ctx.ui.notify("Jira configuration and API token verified.", "info");
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : "Jira setup failed.", "error");
			}
		},
	});

	pi.registerCommand("jira-project", {
		description: "Set this trusted repository's default Jira project: /jira-project ABC",
		handler: async (args, ctx) => {
			try {
				if (!ctx.isProjectTrusted()) {
					throw new Error("Refusing to write .pi/jira.json in an untrusted project.");
				}
				const value = args.trim() || await ctx.ui.input("Default Jira project key", "For example: ABC");
				if (!value) return;
				const defaultProjectKey = normalizeProjectKey(value);
				await writeRepoConfig(ctx.cwd, { defaultProjectKey });
				ctx.ui.notify(`Jira default project: ${defaultProjectKey}`, "info");
			} catch (error) {
				ctx.ui.notify(error instanceof Error ? error.message : "Unable to save Jira project.", "error");
			}
		},
	});

	pi.registerTool({
		name: "jira_search",
		label: "Jira Search",
		description: "Search issues in the repository's configured Jira project. Use projectKey only for an explicit override.",
		parameters: Type.Object({
			query: Type.Optional(Type.String({ description: "JQL conditions without a project clause, for example: statusCategory != Done ORDER BY updated DESC" })),
			projectKey: optionalProject,
			limit: Type.Optional(Type.Integer({ minimum: 1, maximum: 50, description: "Maximum issues to return; defaults to 20." })),
			fields: Type.Optional(issueFields),
		}),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const projectKey = await resolveProject(ctx, params.projectKey);
				const body = await jiraRequest("/search/jql", {
					method: "POST",
					body: {
						jql: scopedJql(projectKey, params.query),
						maxResults: params.limit ?? 20,
						fields: [...new Set([...(params.fields ?? DEFAULT_SEARCH_FIELDS), "project"])],
					},
					signal,
				});
				return textResult(formatJson(restrictSearchResults(body, projectKey)), { projectKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_get",
		label: "Get Jira Issue",
		description: "Retrieve one Jira issue by its explicit key. This is read-only.",
		parameters: Type.Object({
			issueKey: Type.String({ description: "Jira issue key, for example ABC-123." }),
			fields: Type.Optional(issueFields),
		}),
		async execute(_id, params, signal) {
			try {
				const issueKey = normalizeIssueKey(params.issueKey);
				const query = new URLSearchParams({ fields: (params.fields ?? [...DEFAULT_SEARCH_FIELDS, "description", "comment"]).join(",") });
				const body = await jiraRequest(`/issue/${encodeURIComponent(issueKey)}?${query}`, { signal });
				return textResult(formatJson(body), { issueKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_create_metadata",
		label: "Jira Create Metadata",
		description: "Retrieve allowed issue types for a Jira project before creating an issue. This is read-only.",
		parameters: Type.Object({ projectKey: optionalProject }),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const projectKey = await resolveProject(ctx, params.projectKey);
				const body = await jiraRequest(`/issue/createmeta/${encodeURIComponent(projectKey)}/issuetypes`, { signal });
				return textResult(formatJson(body), { projectKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_create",
		label: "Create Jira Issue",
		description: "Create a Jira issue. Always asks the user to confirm the exact target and content before writing.",
		parameters: Type.Object({
			summary: Type.String({ description: "Issue title." }),
			description: Type.String({ description: "Issue description in the user's voice. Preserve the supplied wording." }),
			issueType: Type.Optional(Type.String({ description: "Jira issue type name; defaults to Task. Use jira_create_metadata if uncertain." })),
			projectKey: optionalProject,
			parent: Type.Optional(Type.String({ description: "Parent issue key, for example ABC-123." })),
			labels: Type.Optional(Type.Array(Type.String())),
		}),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const projectKey = await resolveProject(ctx, params.projectKey);
				const issueType = params.issueType?.trim() || "Task";
				const approved = await queueMutation(() => confirmMutation(
					ctx,
					`Create Jira issue in ${projectKey}?`,
					`Type: ${issueType}\n${params.parent !== undefined ? `Parent: ${normalizeIssueKey(params.parent)}\n` : ""}Summary: ${params.summary}\n\nDescription:\n${excerpt(params.description, 1_500)}`,
					signal,
				));
				if (!approved) return textResult("Jira issue creation cancelled.");
				const body = await jiraRequest("/issue", {
					method: "POST",
					body: {
						fields: {
							project: { key: projectKey },
							summary: params.summary,
							description: textToAdf(params.description),
							issuetype: { name: issueType },
							...parentIssueField(params.parent),
							...(params.labels ? { labels: params.labels } : {}),
						},
					},
					signal,
				});
				return textResult(formatJson(body), { projectKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_update",
		label: "Update Jira Issue",
		description: "Update an issue's summary, description, labels, or parent. Always asks the user to confirm before writing.",
		parameters: Type.Object({
			issueKey: Type.String({ description: "Jira issue key." }),
			projectKey: optionalIssueProject,
			summary: Type.Optional(Type.String()),
			description: Type.Optional(Type.String()),
			labels: Type.Optional(Type.Array(Type.String())),
			parent: Type.Optional(Type.String({ description: "Parent issue key, for example ABC-123." })),
		}),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const issueKey = normalizeIssueKey(params.issueKey);
				const projectKey = mutationProject(issueKey, params.projectKey);
				const fields: Record<string, unknown> = {
					...(params.summary !== undefined ? { summary: params.summary } : {}),
					...(params.description !== undefined ? { description: textToAdf(params.description) } : {}),
					...(params.labels !== undefined ? { labels: params.labels } : {}),
					...parentIssueField(params.parent),
				};
				if (Object.keys(fields).length === 0) throw new Error("Specify at least one field to update.");
				const approved = await queueMutation(() => confirmMutation(
					ctx,
					`Update Jira issue ${issueKey}?`,
					`Project: ${projectKey}\n${params.summary !== undefined ? `Summary: ${params.summary}\n` : ""}${params.description !== undefined ? `Description:\n${excerpt(params.description, 1_500)}\n` : ""}${params.labels !== undefined ? `Labels: ${params.labels.join(", ")}\n` : ""}${params.parent !== undefined ? `Parent: ${normalizeIssueKey(params.parent)}` : ""}`,
					signal,
				));
				if (!approved) return textResult("Jira issue update cancelled.");
				await jiraRequest(`/issue/${encodeURIComponent(issueKey)}`, { method: "PUT", body: { fields }, signal });
				return textResult(`Updated ${issueKey}.`, { issueKey, projectKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_transitions",
		label: "Jira Transitions",
		description: "List transitions currently available for an issue. This is read-only.",
		parameters: Type.Object({ issueKey: Type.String({ description: "Jira issue key." }) }),
		async execute(_id, params, signal) {
			try {
				const issueKey = normalizeIssueKey(params.issueKey);
				const body = await jiraRequest(`/issue/${encodeURIComponent(issueKey)}/transitions`, { signal });
				return textResult(formatJson(body), { issueKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_transition",
		label: "Transition Jira Issue",
		description: "Transition an issue by the transition ID returned from jira_transitions. Always asks the user to confirm before writing.",
		parameters: Type.Object({
			issueKey: Type.String({ description: "Jira issue key." }),
			projectKey: optionalIssueProject,
			transitionId: Type.String({ description: "Transition ID from jira_transitions." }),
			transitionName: Type.Optional(Type.String({ description: "Human-readable transition name for the confirmation dialog." })),
		}),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const issueKey = normalizeIssueKey(params.issueKey);
				const projectKey = mutationProject(issueKey, params.projectKey);
				const transitionName = params.transitionName?.trim() || `transition ${params.transitionId}`;
				const approved = await queueMutation(() => confirmMutation(
					ctx,
					`Transition Jira issue ${issueKey}?`,
					`Project: ${projectKey}\nTransition: ${transitionName}`,
					signal,
				));
				if (!approved) return textResult("Jira transition cancelled.");
				await jiraRequest(`/issue/${encodeURIComponent(issueKey)}/transitions`, {
					method: "POST",
					body: { transition: { id: params.transitionId } },
					signal,
				});
				return textResult(`Transitioned ${issueKey} via ${transitionName}.`, { issueKey, projectKey, transitionId: params.transitionId });
			} catch (error) {
				return errorResult(error);
			}
		},
	});

	pi.registerTool({
		name: "jira_comment",
		label: "Comment on Jira Issue",
		description: "Add a comment to an issue in the user's supplied voice. Always asks the user to confirm before writing.",
		parameters: Type.Object({
			issueKey: Type.String({ description: "Jira issue key." }),
			projectKey: optionalIssueProject,
			comment: Type.String({ description: "Comment text in the user's voice. Preserve the supplied wording." }),
		}),
		async execute(_id, params, signal, _update, ctx) {
			try {
				const issueKey = normalizeIssueKey(params.issueKey);
				const projectKey = mutationProject(issueKey, params.projectKey);
				const approved = await queueMutation(() => confirmMutation(
					ctx,
					`Comment on Jira issue ${issueKey}?`,
					`Project: ${projectKey}\n\nComment:\n${excerpt(params.comment, 1_500)}`,
					signal,
				));
				if (!approved) return textResult("Jira comment cancelled.");
				const body = await jiraRequest(`/issue/${encodeURIComponent(issueKey)}/comment`, {
					method: "POST",
					body: { body: textToAdf(params.comment) },
					signal,
				});
				return textResult(formatJson(body), { issueKey, projectKey });
			} catch (error) {
				return errorResult(error);
			}
		},
	});
}
