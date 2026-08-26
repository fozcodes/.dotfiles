import assert from "node:assert/strict";
import test from "node:test";
import { updateProjectPackageExtension } from "./package-config.ts";

test("creates a project autoload delta for a globally installed package", () => {
	assert.deepEqual(
		updateProjectPackageExtension([], "npm:pi-subagents", "index.ts", true),
		[
			{
				source: "npm:pi-subagents",
				autoload: false,
				extensions: ["+index.ts"],
				skills: ["skills/**"],
				prompts: ["prompts/**"],
			},
		],
	);
});

test("preserves project-specific package configuration while updating its extension filter", () => {
	assert.deepEqual(
		updateProjectPackageExtension(
			[
				{
					source: "npm:pi-subagents",
					autoload: false,
					skills: ["+skills/pi-subagents/SKILL.md"],
					extensions: ["+old.ts"],
				},
			],
			"npm:pi-subagents",
			"index.ts",
			false,
		),
		[
			{
				source: "npm:pi-subagents",
				autoload: false,
				skills: ["+skills/pi-subagents/SKILL.md"],
				extensions: ["+old.ts", "-index.ts"],
				prompts: ["prompts/**"],
			},
		],
	);
});
