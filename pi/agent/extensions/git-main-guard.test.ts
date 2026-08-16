import assert from "node:assert/strict";
import test from "node:test";
import { parsePushCommands, pushTargetsMain } from "./git-main-guard.logic.ts";

test("recognizes explicit pushes to main", () => {
	assert.equal(pushTargetsMain("git push origin main"), true);
	assert.equal(pushTargetsMain("git push origin feature:main"), true);
	assert.equal(pushTargetsMain("git push origin HEAD:refs/heads/main"), true);
	assert.equal(pushTargetsMain("git push origin main:feature"), false);
	assert.equal(pushTargetsMain("git -C repo push origin main"), true);
});

test("uses the current branch for an implicit push", () => {
	assert.equal(pushTargetsMain("git push", "main"), true);
	assert.equal(pushTargetsMain("git push origin", "main"), true);
	assert.equal(pushTargetsMain("git push", "feature"), false);
});

test("does not guard dry runs or tag-only pushes", () => {
	assert.equal(pushTargetsMain("git push --dry-run origin main"), false);
	assert.equal(pushTargetsMain("git push --tags", "main"), false);
});

test("guards broad pushes and force pushes", () => {
	assert.equal(pushTargetsMain("git push --all origin", "feature"), true);
	assert.equal(parsePushCommands("git push -fu origin main")[0]?.force, true);
	assert.equal(parsePushCommands("git push origin +main:main")[0]?.force, true);
});

test("finds pushes in a chained shell command", () => {
	assert.equal(pushTargetsMain("git status && git push origin main"), true);
	assert.equal(pushTargetsMain("git status && git push origin feature"), false);
});
