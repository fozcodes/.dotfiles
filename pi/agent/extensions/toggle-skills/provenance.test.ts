import assert from "node:assert/strict";
import test from "node:test";
import { parseSkillLock } from "./provenance.ts";

test("maps skills to the repository recorded by skill-install", () => {
	assert.deepEqual(
		parseSkillLock(
			JSON.stringify({
				version: 3,
				skills: {
					implement: { source: "mattpocock/skills" },
					"show-me": { source: "humanlayer/skills" },
				},
			}),
		),
		{
			implement: "mattpocock/skills",
			"show-me": "humanlayer/skills",
		},
	);
});

test("ignores malformed or incomplete lock metadata", () => {
	assert.deepEqual(parseSkillLock("not json"), {});
	assert.deepEqual(parseSkillLock(JSON.stringify({ skills: { implement: {} } })), {});
});
