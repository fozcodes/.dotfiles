import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import test from "node:test";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { ensureProjectSubagentsTemplate } from "./subagents-template.ts";

const withSettingsFile = (run: (settingsPath: string) => void) => {
	const directory = mkdtempSync(join(tmpdir(), "pi-subagents-settings-"));
	const settingsPath = join(directory, "settings.json");

	try {
		run(settingsPath);
	} finally {
		rmSync(directory, { force: true, recursive: true });
	}
};

test("adds the default watchdog configuration to a project without subagent settings", () => {
	withSettingsFile((settingsPath) => {
		writeFileSync(settingsPath, JSON.stringify({ packages: [] }));

		assert.equal(ensureProjectSubagentsTemplate(settingsPath), true);
		assert.deepEqual(JSON.parse(readFileSync(settingsPath, "utf8")), {
			packages: [],
			subagents: {
				watchdog: {
					enabled: true,
					main: {
						model: "openai-codex/gpt-5.6-luna",
						thinking: "medium",
					},
				},
			},
		});
	});
});

test("does not alter an existing project subagent configuration", () => {
	withSettingsFile((settingsPath) => {
		const settings = {
			subagents: {
				defaultModel: "inherit",
				watchdog: { enabled: false },
			},
		};
		writeFileSync(settingsPath, JSON.stringify(settings));

		assert.equal(ensureProjectSubagentsTemplate(settingsPath), false);
		assert.deepEqual(JSON.parse(readFileSync(settingsPath, "utf8")), settings);
	});
});
