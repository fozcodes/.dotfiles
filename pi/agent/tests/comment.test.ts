import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import comment from "../extensions/comment.ts";

function createHarness() {
	const calls: string[] = [];
	const notifications: Array<[string, string]> = [];
	let editorText: string | undefined;

	const tui = {
		stop: () => calls.push("stop"),
		start: () => calls.push("start"),
		requestRender: (full: boolean) => calls.push(`render:${full}`),
	};

	let handler: ((args: string, ctx: unknown) => Promise<void>) | undefined;
	const pi = {
		registerCommand: (name: string, command: { handler: (args: string, ctx: unknown) => Promise<void> }) => {
			assert.equal(name, "comment");
			handler = command.handler;
		},
	};

	comment(pi as never);

	const assistantEntry = {
		type: "message",
		message: {
			role: "assistant",
			stopReason: "stop",
			content: [{ type: "text", text: "hello world" }],
		},
	};

	const ctx = {
		hasUI: true,
		sessionManager: { getBranch: () => [assistantEntry] },
		ui: {
			notify: (message: string, kind: string) => notifications.push([kind, message]),
			setEditorText: (text: string) => {
				editorText = text;
			},
			custom: (factory: (tui: unknown, theme: undefined, keybindings: undefined, done: (result: unknown) => void) => unknown) => {
				let result: unknown;
				const done = (value: unknown) => {
					result = value;
				};
				factory(tui, undefined, undefined, done);
				return Promise.resolve(result);
			},
		},
	};

	async function run() {
		if (!handler) {
			throw new Error("comment command was not registered");
		}
		await handler("", ctx);
	}

	return { calls, notifications, run, getEditorText: () => editorText };
}

function writeEditorScript(script: string): string {
	const file = path.join(os.tmpdir(), `pi-comment-test-editor-${Date.now()}-${Math.random()}`);
	fs.writeFileSync(file, script, { mode: 0o755 });
	return file;
}

test("stops the TUI around the external editor and loads the edited text", async () => {
	const editor = writeEditorScript('#!/bin/sh\nprintf \'\\nedited\\n\' >> "$1"\n');
	const previousEditor = process.env.EDITOR;
	process.env.EDITOR = editor;
	const harness = createHarness();

	try {
		await harness.run();
	} finally {
		if (previousEditor === undefined) {
			delete process.env.EDITOR;
		} else {
			process.env.EDITOR = previousEditor;
		}
		fs.unlinkSync(editor);
	}

	assert.deepEqual(harness.calls, [
		"stop",
		"start",
		"render:true",
	]);
	assert.equal(harness.getEditorText(), "> hello world\nedited");
	assert.deepEqual(harness.notifications, [
		["info", "Loaded edited quoted assistant text into the editor"],
	]);
});

test("restarts the TUI even when the editor fails, and notifies instead of setting text", async () => {
	const editor = writeEditorScript("#!/bin/sh\nexit 3\n");
	const previousEditor = process.env.EDITOR;
	process.env.EDITOR = editor;
	const harness = createHarness();

	try {
		await harness.run();
	} finally {
		if (previousEditor === undefined) {
			delete process.env.EDITOR;
		} else {
			process.env.EDITOR = previousEditor;
		}
		fs.unlinkSync(editor);
	}

	assert.deepEqual(harness.calls, ["stop", "start", "render:true"]);
	assert.equal(harness.getEditorText(), undefined);
	assert.equal(harness.notifications[0]?.[0], "error");
	assert.match(harness.notifications[0]?.[1] ?? "", /status 3/);
});

test("reports a missing editor configuration as an error", async () => {
	const previousVisual = process.env.VISUAL;
	const previousEditor = process.env.EDITOR;
	delete process.env.VISUAL;
	delete process.env.EDITOR;
	const harness = createHarness();

	try {
		await harness.run();
	} finally {
		if (previousVisual !== undefined) {
			process.env.VISUAL = previousVisual;
		}
		if (previousEditor !== undefined) {
			process.env.EDITOR = previousEditor;
		}
	}

	assert.deepEqual(harness.calls, ["stop", "start", "render:true"]);
	assert.equal(harness.getEditorText(), undefined);
	assert.deepEqual(harness.notifications, [
		["error", "No editor configured. Set VISUAL or EDITOR environment variable."],
	]);
});
