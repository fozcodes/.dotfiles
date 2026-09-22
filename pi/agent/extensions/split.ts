/**
 * Split Extension — /split
 *
 * Corollary of /fork. When you realize you've gone off on a tangent,
 * select the point where it started. Everything from that point forward
 * moves into a new session; the original is truncated at that point.
 *
 * UI: top-to-bottom, earliest-to-latest message (same as /fork).
 */

import {
	UserMessageSelectorComponent,
	type ExtensionAPI,
	type SessionEntry,
} from "@earendil-works/pi-coding-agent";
import { readFileSync, writeFileSync } from "node:fs";
import { basename, dirname, join } from "node:path";

function userMessageText(entry: SessionEntry): string {
	if (entry.type !== "message" || entry.message.role !== "user") return "";
	return typeof entry.message.content === "string"
		? entry.message.content
		: entry.message.content
				.filter((content) => content.type === "text")
				.map((content) => content.text)
				.join(" ");
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("split", {
		description: "Split a tangent into a new session from a selected point forward",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/split requires interactive mode", "error");
				return;
			}

			const sessionFile = ctx.sessionManager.getSessionFile();
			if (!sessionFile) {
				ctx.ui.notify("No persistent session to split", "error");
				return;
			}

			const branch = ctx.sessionManager.getBranch();
			if (branch.length === 0) {
				ctx.ui.notify("No conversation history to split", "error");
				return;
			}

			// getBranch() is already earliest → latest, matching /fork.
			// Filter to user messages only.
			const chronological = branch.slice();
			const userEntries = chronological.filter(
				(entry) => entry.type === "message" && entry.message.role === "user",
			);

			if (userEntries.length === 0) {
				ctx.ui.notify("No user messages to split from", "error");
				return;
			}

			const selectedEntryId = await ctx.ui.custom<string | undefined>((tui, _theme, _keybindings, done) => {
				const selector = new UserMessageSelectorComponent(
					userEntries.map((entry) => ({ id: entry.id, text: userMessageText(entry) })),
					done,
					() => done(undefined),
					userEntries.at(-1)?.id,
				);
				const messageList = selector.getMessageList();

				return {
					render: (width) => selector.render(width),
					invalidate: () => selector.invalidate(),
					handleInput: (data) => {
						messageList.handleInput(data);
						tui.requestRender();
					},
				};
			});
			if (!selectedEntryId) {
				ctx.ui.notify("Split cancelled", "info");
				return;
			}

			const selectedEntry = userEntries.find((entry) => entry.id === selectedEntryId);
			if (!selectedEntry) {
				ctx.ui.notify("Invalid selection", "error");
				return;
			}
			// forwardCount includes all entries from this user message onward
			const chronologicalIdx = chronological.findIndex((e) => e.id === selectedEntry.id);
			const forwardCount = chronological.length - chronologicalIdx;

			const ok = await ctx.ui.confirm(
				"Split session",
				`New session will contain ${forwardCount} entries from this point forward.\nOriginal session will be truncated here.\n\nProceed?`,
			);
			if (!ok) {
				ctx.ui.notify("Split cancelled", "info");
				return;
			}

			// Read current session file
			const content = readFileSync(sessionFile, "utf-8");
			const [headerLine, ...entryLines] = content.trim().split("\n");
			if (!headerLine) {
				ctx.ui.notify("Empty session file", "error");
				return;
			}

			const header = JSON.parse(headerLine);
			const allEntries: SessionEntry[] = [];
			for (const entryLine of entryLines) {
				const line = entryLine.trim();
				if (line) allEntries.push(JSON.parse(line));
			}

			// Find split position in the full file (not just active branch)
			const splitPosition = allEntries.findIndex((e) => e.id === selectedEntry.id);
			if (splitPosition === -1) {
				ctx.ui.notify("Split point not found in session file", "error");
				return;
			}

			const forwardEntries = allEntries.slice(splitPosition);
			const keptEntries = allEntries.slice(0, splitPosition);

			// Create new session file for the tangent
			const sessionDir = dirname(sessionFile);
			const timestamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
			const newSessionFile = join(sessionDir, `${timestamp}_split.jsonl`);

			const newHeader = {
				...header,
				id: crypto.randomUUID(),
				timestamp: new Date().toISOString(),
				parentSession: sessionFile,
			};

			const newLines = [JSON.stringify(newHeader)];
			let newParentId: string | null = null;
			for (const entry of forwardEntries) {
				newLines.push(JSON.stringify({ ...entry, parentId: newParentId }));
				newParentId = entry.id;
			}
			writeFileSync(newSessionFile, newLines.join("\n") + "\n");

			// Truncate original session file
			const originalLines = [JSON.stringify(header)];
			for (const entry of keptEntries) {
				originalLines.push(JSON.stringify(entry));
			}
			writeFileSync(sessionFile, originalLines.join("\n") + "\n");

			// Switch to the new session
			const result = await ctx.switchSession(newSessionFile, {
				withSession: async (newCtx) => {
					newCtx.ui.notify(
						`Split complete. Tangent moved to ${basename(newSessionFile)}`,
						"info",
					);
				},
			});

			if (result.cancelled) {
				ctx.ui.notify("Session switch cancelled", "info");
			}
		},
	});
}
