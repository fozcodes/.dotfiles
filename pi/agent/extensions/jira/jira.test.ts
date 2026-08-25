import assert from "node:assert/strict";
import test from "node:test";
import {
	assigneeField,
	basicAuthorization,
	createAsyncQueue,
	normalizeIssueKey,
	normalizeProjectKey,
	parentIssueField,
	normalizeSiteUrl,
	parseGlobalConfig,
	parseRepoConfig,
	restrictSearchResults,
	scopedJql,
	textToAdf,
} from "./jira.ts";

test("normalizes Jira site URLs", () => {
	assert.equal(normalizeSiteUrl(" https://company.atlassian.net/ "), "https://company.atlassian.net");
	assert.throws(() => normalizeSiteUrl("http://company.atlassian.net"), /HTTPS/);
	assert.throws(() => normalizeSiteUrl("https://company.atlassian.net/jira"), /origin/);
});

test("validates and normalizes project and issue keys", () => {
	assert.equal(normalizeProjectKey(" platform_2 "), "PLATFORM_2");
	assert.equal(normalizeIssueKey(" platform_2-42 "), "PLATFORM_2-42");
	assert.throws(() => normalizeProjectKey("X"), /project key/);
	assert.throws(() => normalizeIssueKey("PROJECT-zero"), /issue key/);
});

test("builds validated parent and assignee fields", () => {
	assert.deepEqual(parentIssueField(), {});
	assert.deepEqual(parentIssueField(" platform_2-42 "), { parent: { key: "PLATFORM_2-42" } });
	assert.throws(() => parentIssueField("not-an-issue"), /issue key/);
	assert.deepEqual(assigneeField(), {});
	assert.deepEqual(assigneeField(" 123:account-id "), { assignee: { accountId: "123:account-id" } });
	assert.throws(() => assigneeField(" "), /account ID/);
});

test("parses only required configuration", () => {
	assert.deepEqual(
		parseGlobalConfig({ siteUrl: "https://company.atlassian.net", email: "me@company.com", token: "jira-token", ignored: true }),
		{ siteUrl: "https://company.atlassian.net", email: "me@company.com", token: "jira-token" },
	);
	assert.deepEqual(parseRepoConfig({ defaultProjectKey: "abc" }), { defaultProjectKey: "ABC" });
	assert.throws(() => parseGlobalConfig({ siteUrl: "https://company.atlassian.net" }), /requires/);
	assert.throws(() => parseRepoConfig({}), /requires/);
});

test("keeps search queries scoped to the selected project", () => {
	assert.equal(scopedJql("abc", "statusCategory != Done ORDER BY updated DESC"), "project = ABC AND (statusCategory != Done) ORDER BY updated DESC");
	assert.equal(scopedJql("abc"), "project = ABC");
	assert.equal(scopedJql("abc", "ORDER BY created ASC"), "project = ABC ORDER BY created ASC");
});

test("filters search results back to the selected project", () => {
	assert.deepEqual(
		restrictSearchResults({
			total: 2,
			issues: [
				{ key: "ABC-1", fields: { project: { key: "ABC" } } },
				{ key: "OTHER-1", fields: { project: { key: "OTHER" } } },
			],
		}, "abc"),
		{
			total: 1,
			projectKey: "ABC",
			issues: [{ key: "ABC-1", fields: { project: { key: "ABC" } } }],
		},
	);
});

test("converts plain text to Atlassian Document Format", () => {
	assert.deepEqual(textToAdf("First paragraph\n\nSecond paragraph"), {
		type: "doc",
		version: 1,
		content: [
			{ type: "paragraph", content: [{ type: "text", text: "First paragraph" }] },
			{ type: "paragraph" },
			{ type: "paragraph", content: [{ type: "text", text: "Second paragraph" }] },
		],
	});
});

test("uses stored tokens for basic auth", () => {
	assert.equal(basicAuthorization("me@company.com", "token"), "Basic bWVAY29tcGFueS5jb206dG9rZW4=");
});

test("serializes queued mutations", async () => {
	const queue = createAsyncQueue();
	const events: string[] = [];
	let releaseGate: (() => void) | undefined;
	const gate = new Promise<void>((resolve) => {
		releaseGate = resolve;
	});
	const first = queue(async () => {
		events.push("first started");
		await gate;
		events.push("first completed");
		return 1;
	});
	const second = queue(async () => {
		events.push("second started");
		return 2;
	});

	await Promise.resolve();
	assert.deepEqual(events, ["first started"]);
	releaseGate?.();
	assert.deepEqual(await Promise.all([first, second]), [1, 2]);
	assert.deepEqual(events, ["first started", "first completed", "second started"]);
});
