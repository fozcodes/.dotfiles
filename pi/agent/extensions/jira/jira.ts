import { chmod, mkdir, readFile, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";

export const DEFAULT_SEARCH_FIELDS = [
	"summary",
	"status",
	"issuetype",
	"priority",
	"labels",
	"assignee",
	"reporter",
	"created",
	"updated",
];

export type GlobalConfig = Readonly<{
	siteUrl: string;
	email: string;
	token?: string;
}>;

export type RepoConfig = Readonly<{
	defaultProjectKey: string;
}>;

export type AdfDocument = Readonly<{
	type: "doc";
	version: 1;
	content: ReadonlyArray<Readonly<{
		type: "paragraph";
		content?: ReadonlyArray<Readonly<{
			type: "text";
			text: string;
		}>>;
	}>>;
}>;

const asRecord = (value: unknown) =>
	typeof value === "object" && value !== null && !Array.isArray(value)
		? value as Record<string, unknown>
		: undefined;

const requiredString = (record: Record<string, unknown>, key: string) => {
	const value = record[key];
	return typeof value === "string" && value.trim() ? value.trim() : undefined;
};

export const normalizeSiteUrl = (value: string) => {
	const url = new URL(value.trim());
	if (url.protocol !== "https:") {
		throw new Error("Jira site URL must use HTTPS.");
	}
	if (url.pathname !== "/" || url.search || url.hash || url.username || url.password) {
		throw new Error("Jira site URL must be an origin, for example https://company.atlassian.net.");
	}
	return url.origin;
};

export const normalizeProjectKey = (value: string) => {
	const key = value.trim().toUpperCase();
	if (!/^[A-Z][A-Z0-9_]{1,9}$/.test(key)) {
		throw new Error("Jira project key must be 2–10 uppercase letters, numbers, or underscores.");
	}
	return key;
};

export const normalizeIssueKey = (value: string) => {
	const key = value.trim().toUpperCase();
	if (!/^[A-Z][A-Z0-9_]{1,9}-[1-9][0-9]*$/.test(key)) {
		throw new Error("Jira issue key must look like PROJECT-123.");
	}
	return key;
};

export const projectFromIssueKey = (issueKey: string) => normalizeIssueKey(issueKey).split("-")[0]!;

export const parentIssueField = (parent?: string) =>
	parent === undefined ? {} : { parent: { key: normalizeIssueKey(parent) } };

export const assigneeField = (accountId?: string) => {
	if (accountId === undefined) return {};
	const normalizedAccountId = accountId.trim();
	if (!normalizedAccountId) throw new Error("Jira assignee account ID is required.");
	return { assignee: { accountId: normalizedAccountId } };
};

export const parseGlobalConfig = (value: unknown) => {
	const record = asRecord(value);
	if (!record) {
		throw new Error("Global Jira configuration must be a JSON object.");
	}
	const siteUrl = requiredString(record, "siteUrl");
	const email = requiredString(record, "email");
	if (!siteUrl || !email) {
		throw new Error("Global Jira configuration requires siteUrl and email.");
	}
	const token = requiredString(record, "token");
	return {
		siteUrl: normalizeSiteUrl(siteUrl),
		email,
		...(token ? { token } : {}),
	} satisfies GlobalConfig;
};

export const parseRepoConfig = (value: unknown) => {
	const record = asRecord(value);
	if (!record) {
		throw new Error("Repository Jira configuration must be a JSON object.");
	}
	const defaultProjectKey = requiredString(record, "defaultProjectKey");
	if (!defaultProjectKey) {
		throw new Error("Repository Jira configuration requires defaultProjectKey.");
	}
	return { defaultProjectKey: normalizeProjectKey(defaultProjectKey) } satisfies RepoConfig;
};

export const createAsyncQueue = () => {
	let tail = Promise.resolve();
	return async <Value>(operation: () => Promise<Value>) => {
		const result = tail.then(operation, operation);
		tail = result.then(() => undefined, () => undefined);
		return result;
	};
};

export const configDir = () => process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
export const globalConfigPath = () => join(configDir(), "jira.json");
export const repoConfigPath = (cwd: string) => join(cwd, ".pi", "jira.json");

const readJson = async (path: string) => {
	try {
		return JSON.parse(await readFile(path, "utf8")) as unknown;
	} catch (error) {
		if (error instanceof Error && "code" in error && error.code === "ENOENT") {
			return undefined;
		}
		throw error;
	}
};

export const readGlobalConfig = async () => {
	const value = await readJson(globalConfigPath());
	if (!value) {
		throw new Error("Jira is not configured. Run /jira-setup first.");
	}
	return parseGlobalConfig(value);
};

export const readRepoConfig = async (cwd: string) => {
	const value = await readJson(repoConfigPath(cwd));
	return value ? parseRepoConfig(value) : undefined;
};

export const writeGlobalConfig = async (config: GlobalConfig) => {
	const path = globalConfigPath();
	await mkdir(dirname(path), { recursive: true });
	await writeFile(path, `${JSON.stringify(config, undefined, "\t")}\n`, { mode: 0o600 });
	await chmod(path, 0o600);
};

export const writeRepoConfig = async (cwd: string, config: RepoConfig) => {
	const path = repoConfigPath(cwd);
	await mkdir(dirname(path), { recursive: true });
	await writeFile(path, `${JSON.stringify(config, undefined, "\t")}\n`, { mode: 0o600 });
};

export const basicAuthorization = (email: string, token: string) =>
	`Basic ${Buffer.from(`${email}:${token}`).toString("base64")}`;

export const textToAdf = (text: string): AdfDocument => ({
	type: "doc",
	version: 1,
	content: text.split("\n").map((line) => ({
		type: "paragraph" as const,
		...(line ? { content: [{ type: "text" as const, text: line }] } : {}),
	})),
});

export const scopedJql = (projectKey: string, query?: string) => {
	const scope = `project = ${normalizeProjectKey(projectKey)}`;
	const trimmedQuery = query?.trim();
	if (!trimmedQuery) return scope;
	const orderByIndex = trimmedQuery.search(/(?:^|\s+)ORDER\s+BY\s+/i);
	const conditions = orderByIndex === -1 ? trimmedQuery : trimmedQuery.slice(0, orderByIndex).trim();
	const ordering = orderByIndex === -1 ? "" : ` ${trimmedQuery.slice(orderByIndex).trim()}`;
	return conditions ? `${scope} AND (${conditions})${ordering}` : `${scope}${ordering}`;
};

export const restrictSearchResults = (value: unknown, projectKey: string) => {
	const record = asRecord(value);
	if (!record || !Array.isArray(record.issues)) return value;
	const targetProject = normalizeProjectKey(projectKey);
	const issues = record.issues.filter((issue) => {
		const fields = asRecord(asRecord(issue)?.fields);
		const project = asRecord(fields?.project);
		return project?.key === targetProject;
	});
	return { ...record, issues, total: issues.length, projectKey: targetProject };
};

export const excerpt = (text: string, maxLength = 600) =>
	text.length <= maxLength ? text : `${text.slice(0, maxLength - 1)}…`;
