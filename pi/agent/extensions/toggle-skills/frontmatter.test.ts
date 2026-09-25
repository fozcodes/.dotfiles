import assert from "node:assert/strict";
import test from "node:test";
import { setSkillModelInvocation } from "./frontmatter.ts";

const skill = (frontmatter: string) => `---\n${frontmatter}---\n# Skill\n`;

test("marks a skill manual-only without changing its existing metadata", () => {
	assert.equal(
		setSkillModelInvocation(skill("name: test\ndescription: A test skill\n"), true),
		skill("name: test\ndescription: A test skill\ndisable-model-invocation: true\n"),
	);
});

test("removes model-invocation settings when enabling a skill", () => {
	assert.equal(
		setSkillModelInvocation(
			skill("name: test\ndisable-model-invocation: true\ndescription: A test skill\n"),
			false,
		),
		skill("name: test\ndescription: A test skill\n"),
	);
});

test("normalizes duplicate model-invocation settings", () => {
	assert.equal(
		setSkillModelInvocation(
			skill("name: test\ndisable-model-invocation: false\ndisable-model-invocation: true\n"),
			true,
		),
		skill("name: test\ndisable-model-invocation: true\n"),
	);
});

test("preserves CRLF line endings", () => {
	const source = "---\r\nname: test\r\n---\r\n# Skill\r\n";
	assert.equal(
		setSkillModelInvocation(source, true),
		"---\r\nname: test\r\ndisable-model-invocation: true\r\n---\r\n# Skill\r\n",
	);
});

test("rejects malformed skills instead of writing outside frontmatter", () => {
	assert.throws(() => setSkillModelInvocation("# Skill\n", true), /no frontmatter/);
	assert.throws(() => setSkillModelInvocation("---\nname: test\n", true), /no closing delimiter/);
});
