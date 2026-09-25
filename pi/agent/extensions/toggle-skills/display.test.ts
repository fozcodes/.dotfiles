import assert from "node:assert/strict";
import test from "node:test";
import type { Skill } from "@earendil-works/pi-coding-agent";
import { formatSkillColumnHeader, formatSkillColumns, formatSkillDetails } from "./display.ts";

const skill: Skill = {
	name: "example-skill",
	description: "Does example work.",
	filePath: "/packages/example/skills/example/SKILL.md",
	baseDir: "/packages/example/skills/example",
	sourceInfo: {
		path: "/packages/example/skills/example/SKILL.md",
		source: "npm:example-pkg",
		scope: "user",
		origin: "package",
		baseDir: "/packages/example",
	},
	disableModelInvocation: false,
};

test("formats source as a fixed-width skills-list column", () => {
	assert.equal(formatSkillColumnHeader(), "Name              Source            ");
	assert.equal(formatSkillColumns(skill), "example-skill     npm:example-pkg   ");
});

test("includes package provenance and installed location in skill details", () => {
	assert.equal(
		formatSkillDetails(skill),
		[
			"Source: npm:example-pkg",
			"Origin: package (user)",
			"Installed at: /packages/example",
			"Skill file: /packages/example/skills/example/SKILL.md",
			"",
			"Does example work.",
		].join("\n"),
	);
});
