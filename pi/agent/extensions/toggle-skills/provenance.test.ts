import assert from "node:assert/strict";
import test from "node:test";
import {
	matchSkillPublisher,
	parsePublisherOverrides,
	parseSkillLock,
} from "./provenance.ts";

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

test("reads author overrides scoped to the installing repository", () => {
	assert.deepEqual(
		parsePublisherOverrides(
			JSON.stringify({
				"mattpocock/skills": { caveman: "JuliusBrussee/caveman" },
			}),
		),
		{
			"mattpocock/skills": { caveman: "JuliusBrussee/caveman" },
		},
	);
});

test("attributes duplicate skills only when their contents match", () => {
	const publishers = { implement: "mattpocock/skills" };
	assert.equal(
		matchSkillPublisher("implement", "same skill", "same skill", publishers),
		"mattpocock/skills",
	);
	assert.equal(matchSkillPublisher("implement", "local edit", "upstream skill", publishers), undefined);
});

test("ignores malformed or incomplete lock metadata", () => {
	assert.deepEqual(parseSkillLock("not json"), {});
	assert.deepEqual(parseSkillLock(JSON.stringify({ skills: { implement: {} } })), {});
});
