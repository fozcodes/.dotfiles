import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import {
	buildExtensionDetails,
	getExtensionDetails,
	getLeadingDocblock,
	toggleDetailDescriptions,
} from "./details.ts";

test("extracts and normalizes a leading docblock", () => {
	const source = `/**
 * History Visual Yank
 *
 * Browse session history and copy selected text.
 */
export default {};`;

	assert.equal(
		getLeadingDocblock(source),
		"History Visual Yank\n\nBrowse session history and copy selected text.",
	);
});

test("supports a BOM, whitespace, CRLF, and single-line docblocks", () => {
	assert.equal(getLeadingDocblock("\uFEFF\r\n  /**\r\n   * Details\r\n   */\r\nexport {};"), "Details");
	assert.equal(getLeadingDocblock("/** Details */\nexport {};"), "Details");
});

test("ignores empty, unterminated, and non-leading docblocks", () => {
	assert.equal(getLeadingDocblock("/** */\nexport {};"), undefined);
	assert.equal(getLeadingDocblock("/** Details\nexport {};"), undefined);
	assert.equal(getLeadingDocblock("const value = 1;\n/** Details */"), undefined);
});

test("uses docblocks only when a package description is unavailable", () => {
	assert.equal(
		buildExtensionDetails("/extensions/local.ts", "Local extension", {}),
		"Local extension\n\nEntrypoint: /extensions/local.ts",
	);
	assert.equal(
		buildExtensionDetails("/extensions/package.ts", "Docblock", {
			identity: "example-extension v1.0.0",
			description: "Package description",
		}),
		"example-extension v1.0.0\n\nPackage description\n\nEntrypoint: /extensions/package.ts",
	);
	assert.equal(
		buildExtensionDetails("/extensions/package.ts", "Docblock fallback", {
			identity: "example-extension v1.0.0",
		}),
		"example-extension v1.0.0\n\nDocblock fallback\n\nEntrypoint: /extensions/package.ts",
	);
});

test("reads package metadata and docblocks from extension fixtures", (t) => {
	const directory = mkdtempSync(join(tmpdir(), "pi-extension-details-"));
	t.after(() => rmSync(directory, { recursive: true, force: true }));

	const localExtension = join(directory, "local.ts");
	writeFileSync(localExtension, "/** Local extension */\nexport default {};\n");
	assert.equal(
		getExtensionDetails(localExtension, undefined),
		`Local extension\n\nEntrypoint: ${localExtension}`,
	);

	const packageDirectory = join(directory, "package");
	mkdirSync(packageDirectory);
	const packageExtension = join(packageDirectory, "index.ts");
	writeFileSync(packageExtension, "/** Package docblock */\nexport default {};\n", { flush: true });
	writeFileSync(
		join(packageDirectory, "package.json"),
		JSON.stringify({ name: "package-extension", version: "1.2.3", description: "Package description" }),
		{ flush: true },
	);
	assert.equal(
		getExtensionDetails(packageExtension, packageDirectory),
		`package-extension v1.2.3\n\nPackage description\n\nEntrypoint: ${packageExtension}`,
	);

	writeFileSync(join(packageDirectory, "package.json"), JSON.stringify({ name: "package-extension" }), { flush: true });
	assert.equal(
		getExtensionDetails(packageExtension, packageDirectory),
		`package-extension\n\nPackage docblock\n\nEntrypoint: ${packageExtension}`,
	);
});

test("toggles item descriptions between paths and details", () => {
	const resources = [{ id: "local", path: "/extensions/local.ts", details: "Local extension" }];
	const items = [{ id: "local", description: "/extensions/local.ts" }];

	let showingDetails = toggleDetailDescriptions(false, resources, items);
	assert.equal(showingDetails, true);
	assert.equal(items[0]?.description, "Local extension");

	showingDetails = toggleDetailDescriptions(showingDetails, resources, items);
	assert.equal(showingDetails, false);
	assert.equal(items[0]?.description, "/extensions/local.ts");
});
