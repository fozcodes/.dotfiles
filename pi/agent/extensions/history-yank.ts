/**
 * History Visual Yank
 *
 * /yank or Ctrl+Shift+Y opens a vim-ish history browser:
 *   h/j/k/l or arrows  move cursor
 *   Ctrl+d/u           page down/up
 *   g/G                top/bottom
 *   0/$                line start/end
 *   e/b                word end/back
 *   v                  start/clear character visual selection
 *   V                  start/clear line visual selection
 *   y                  copy cursor line or visual selection to clipboard
 *   q/Escape           close
 */

import { spawn } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui";

type Entry = { id: string; type: string; message?: any };
type HistoryLine = {
	text: string;
	raw: string;
	entryId: string;
	role: string;
	kind: "label" | "content" | "spacer";
};

const VIEW_ROWS = 24;

function contentToText(content: any): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";
	return content
		.map((block) => {
			if (!block || typeof block !== "object") return "";
			if (block.type === "text") return block.text ?? "";
			if (block.type === "thinking") return `✻ Thinking\n${block.thinking ?? ""}`;
			if (block.type === "toolCall") return `⏺ ${block.name ?? "tool"}(${Object.keys(block.arguments ?? {}).join(", ")})`;
			if (block.type === "image") return `[image: ${block.mimeType ?? block.mediaType ?? "unknown"}]`;
			return "";
		})
		.filter(Boolean)
		.join("\n");
}

function roleOf(message: any): string {
	if (!message?.role) return "unknown";
	if (message.role === "toolResult") return `tool:${message.toolName ?? "result"}`;
	if (message.role === "custom") return `custom:${message.customType ?? "message"}`;
	return message.role;
}

function messageToText(message: any): string {
	if (!message) return "";
	if (message.role === "bashExecution") return `$ ${message.command ?? ""}\n${message.output ?? ""}`.trim();
	if (message.role === "branchSummary" || message.role === "compactionSummary") return message.summary ?? "";
	return contentToText(message.content);
}

function decodeHtmlEntities(text: string): string {
	return text
		.replace(/&nbsp;/g, " ")
		.replace(/&amp;/g, "&")
		.replace(/&lt;/g, "<")
		.replace(/&gt;/g, ">")
		.replace(/&quot;/g, '"')
		.replace(/&#39;/g, "'");
}

function cleanForDisplay(text: string): string {
	// Session/export artifacts sometimes contain HTML wrappers. Make the yank view
	// look like the transcript, not like exported markup.
	return decodeHtmlEntities(
		text
			.replace(/<br\s*\/?>/gi, "\n")
			.replace(/<\/p>/gi, "\n")
			.replace(/<\/?(?:div|span|p|pre|code|details|summary|html|body)[^>]*>/gi, "")
			.replace(/\x1b\[[0-9;]*m/g, ""),
	);
}

function labelFor(role: string, id: string): string {
	if (role === "user") return "You";
	if (role === "assistant") return "Assistant";
	if (role.startsWith("tool:")) return role.replace("tool:", "Tool: ");
	if (role === "bashExecution") return "Bash";
	return role[0]?.toUpperCase() + role.slice(1) || id;
}

function buildHistoryLines(ctx: any): HistoryLine[] {
	const branch = ctx.sessionManager.getBranch() as Entry[];
	const lines: HistoryLine[] = [];

	for (const entry of branch) {
		if (entry.type !== "message" || !entry.message) continue;
		const role = roleOf(entry.message);
		const text = messageToText(entry.message);
		const label = labelFor(role, entry.id);
		lines.push({ text: label, raw: `--- ${label.toUpperCase()} ${entry.id} ---`, entryId: entry.id, role, kind: "label" });
		for (const raw of (text || "(empty)").split("\n")) {
			lines.push({ text: cleanForDisplay(raw), raw, entryId: entry.id, role, kind: "content" });
		}
		lines.push({ text: "", raw: "", entryId: entry.id, role, kind: "spacer" });
	}

	return lines.length ? lines : [{ text: "No history", raw: "", entryId: "", role: "", kind: "content" }];
}

function runClipboardCommand(command: string, args: string[], text: string): Promise<void> {
	return new Promise((resolve, reject) => {
		const child = spawn(command, args, { stdio: ["pipe", "ignore", "pipe"] });
		let stderr = "";
		child.stderr.on("data", (chunk: Buffer) => (stderr += String(chunk)));
		child.on("error", reject);
		child.on("close", (code: number | null) => {
			if (code === 0) resolve();
			else reject(new Error(`${command} exited ${code}${stderr ? `: ${stderr.trim()}` : ""}`));
		});
		child.stdin.end(text);
	});
}

async function copyToClipboard(text: string): Promise<void> {
	if (process.platform === "darwin") return runClipboardCommand("pbcopy", [], text);
	if (process.platform === "win32") return runClipboardCommand("clip.exe", [], text);

	let lastError: unknown;
	for (const [cmd, args] of [["wl-copy", []], ["xclip", ["-selection", "clipboard"]], ["xsel", ["--clipboard", "--input"]]] as Array<[string, string[]]>) {
		try {
			await runClipboardCommand(cmd, args, text);
			return;
		} catch (error) {
			lastError = error;
		}
	}
	throw lastError ?? new Error("No clipboard command found");
}

type Position = { line: number; col: number };
type VisualMode = "char" | "line";

class HistoryYankPane {
	private cursor: Position = { line: 0, col: 0 };
	private top = 0;
	private visualAnchor: Position | null = null;
	private visualMode: VisualMode | null = null;
	private horizontal = 0;
	private viewportTextWidth = 60;

	constructor(
		private readonly lines: HistoryLine[],
		private readonly theme: any,
		private readonly done: (value: string[] | null) => void,
	) {}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || data === "q") return this.done(null);
		if (data === "j" || matchesKey(data, "down")) return this.moveLine(1);
		if (data === "k" || matchesKey(data, "up")) return this.moveLine(-1);
		if (data === "h" || matchesKey(data, "left")) return this.moveCol(-1);
		if (data === "l" || matchesKey(data, "right")) return this.moveCol(1);
		if (matchesKey(data, "ctrl+d") || matchesKey(data, "pageDown")) return this.moveLine(Math.floor(VIEW_ROWS / 2));
		if (matchesKey(data, "ctrl+u") || matchesKey(data, "pageUp")) return this.moveLine(-Math.floor(VIEW_ROWS / 2));
		if (data === "g") return this.jumpLine(0);
		if (data === "G") return this.jumpLine(this.lines.length - 1);
		if (data === "0") return this.setCol(0);
		if (data === "$") return this.setCol(this.currentLineText().length);
		if (data === "e") return this.moveWordEndForward();
		if (data === "b") return this.moveWordStartBackward();
		if (data === "v") return this.toggleVisual("char");
		if (data === "V") return this.toggleVisual("line");
		if (data === "y") return this.yank();
	}

	render(width: number): string[] {
		this.ensureVisible();
		const out: string[] = [];
		const mode = this.visualMode === null ? "normal" : this.visualMode === "line" ? "visual line" : "visual";
		out.push(this.theme.fg("dim", `history yank (${mode})  h/j/k/l move  e/b word  v char  V line  y yank  q close`));
		out.push(this.theme.fg("dim", "─".repeat(Math.max(0, width))));

		const textWidth = Math.max(10, width - 2);
		this.viewportTextWidth = textWidth;
		this.ensureVisible();
		for (let row = 0; row < VIEW_ROWS; row++) {
			const index = this.top + row;
			if (index >= this.lines.length) break;
			const line = this.lines[index]!;
			const cursor = index === this.cursor.line ? this.theme.fg("accent", "▌") : " ";
			const body = this.renderHistoryLine(line, index, textWidth);
			const rendered = `${cursor} ${body}`;
			out.push(truncateToWidth(rendered, width, ""));
		}

		const status = this.selectionStatus();
		out.push(this.theme.fg("dim", "─".repeat(Math.max(0, width))));
		out.push(this.theme.fg("dim", `${this.cursor.line + 1}:${this.cursor.col + 1}/${this.lines.length} • ${status}`));
		return out.flatMap((line) => wrapTextWithAnsi(line, width));
	}

	invalidate(): void {}

	private renderHistoryLine(line: HistoryLine, lineIndex: number, width: number): string {
		if (line.kind === "spacer") return "";

		const visibleStart = this.horizontal;
		const visibleEnd = this.horizontal + width;
		const visibleText = line.text.slice(visibleStart, visibleEnd);
		const selectedRange = this.selectedColsForLine(lineIndex);
		const cursorCol = this.visualMode === null && lineIndex === this.cursor.line ? this.cursor.col : null;

		let rendered = "";
		for (let i = 0; i < visibleText.length; i++) {
			const col = visibleStart + i;
			let ch = visibleText[i] ?? " ";
			if (cursorCol === col) ch = this.theme.bg("selectedBg", ch === "" ? " " : ch);
			else if (selectedRange && col >= selectedRange[0] && col < selectedRange[1]) ch = this.theme.bg("selectedBg", ch);
			rendered += ch;
		}
		if (cursorCol === line.text.length && cursorCol >= visibleStart && cursorCol <= visibleEnd) {
			rendered += this.theme.bg("selectedBg", " ");
		}
		if (rendered === "" && selectedRange && selectedRange[0] <= visibleStart && selectedRange[1] > visibleStart) {
			rendered = this.theme.bg("selectedBg", " ");
		}

		const clipped = truncateToWidth(rendered, width, "");
		if (line.kind === "label") {
			return line.role === "user" ? this.theme.fg("userMessageText", clipped) : this.theme.fg("accent", clipped);
		}
		if (line.role === "user") return this.theme.fg("userMessageText", clipped);
		if (line.role.startsWith("tool:")) return this.theme.fg("toolOutput", clipped);
		if (line.role === "bashExecution") return this.theme.fg("toolOutput", clipped);
		if (line.role === "custom") return this.theme.fg("customMessageText", clipped);
		return clipped;
	}

	private moveLine(delta: number): void {
		this.cursor.line = Math.max(0, Math.min(this.lines.length - 1, this.cursor.line + delta));
		this.clampCol();
		this.ensureVisible();
	}

	private moveCol(delta: number): void {
		const next = this.cursor.col + delta;
		if (next < 0 && this.cursor.line > 0) {
			this.cursor.line--;
			this.cursor.col = this.currentLineText().length;
		} else if (next > this.currentLineText().length && this.cursor.line < this.lines.length - 1) {
			this.cursor.line++;
			this.cursor.col = 0;
		} else {
			this.cursor.col = Math.max(0, Math.min(this.currentLineText().length, next));
		}
		this.ensureVisible();
	}

	private jumpLine(index: number): void {
		this.cursor.line = Math.max(0, Math.min(this.lines.length - 1, index));
		this.clampCol();
		this.ensureVisible();
	}

	private setCol(value: number): void {
		this.cursor.col = Math.max(0, Math.min(this.currentLineText().length, value));
		this.ensureVisible();
	}

	private isWordChar(ch: string | undefined): boolean {
		return !!ch && /[A-Za-z0-9_]/.test(ch);
	}

	private moveWordEndForward(): void {
		let line = this.cursor.line;
		let col = this.cursor.col + 1;

		while (line < this.lines.length) {
			const text = this.lines[line]?.text ?? "";
			while (col < text.length && !this.isWordChar(text[col])) col++;
			if (col < text.length) {
				while (col + 1 < text.length && this.isWordChar(text[col + 1])) col++;
				this.cursor = { line, col };
				this.ensureVisible();
				return;
			}
			line++;
			col = 0;
		}

		this.jumpLine(this.lines.length - 1);
		this.setCol(this.currentLineText().length);
	}

	private moveWordStartBackward(): void {
		let line = this.cursor.line;
		let col = this.cursor.col - 1;

		while (line >= 0) {
			const text = this.lines[line]?.text ?? "";
			if (col >= text.length) col = text.length - 1;
			while (col >= 0 && !this.isWordChar(text[col])) col--;
			if (col >= 0) {
				while (col - 1 >= 0 && this.isWordChar(text[col - 1])) col--;
				this.cursor = { line, col };
				this.ensureVisible();
				return;
			}
			line--;
			col = this.lines[line]?.text.length ?? 0;
		}

		this.cursor = { line: 0, col: 0 };
		this.ensureVisible();
	}

	private toggleVisual(mode: VisualMode): void {
		if (this.visualMode === mode) {
			this.visualMode = null;
			this.visualAnchor = null;
			return;
		}
		this.visualMode = mode;
		this.visualAnchor = { ...this.cursor };
	}

	private currentLineText(): string {
		return this.lines[this.cursor.line]?.text ?? "";
	}

	private clampCol(): void {
		this.cursor.col = Math.max(0, Math.min(this.currentLineText().length, this.cursor.col));
	}

	private ensureVisible(): void {
		if (this.cursor.line < this.top) this.top = this.cursor.line;
		if (this.cursor.line >= this.top + VIEW_ROWS) this.top = this.cursor.line - VIEW_ROWS + 1;
		this.top = Math.max(0, Math.min(this.top, Math.max(0, this.lines.length - VIEW_ROWS)));

		const viewWidth = this.viewportTextWidth;
		if (this.cursor.col < this.horizontal) this.horizontal = this.cursor.col;
		if (this.cursor.col >= this.horizontal + viewWidth) this.horizontal = this.cursor.col - viewWidth + 1;
		this.horizontal = Math.max(0, this.horizontal);
	}

	private compare(a: Position, b: Position): number {
		return a.line === b.line ? a.col - b.col : a.line - b.line;
	}

	private orderedSelection(): [Position, Position] | null {
		if (!this.visualAnchor || !this.visualMode) return null;
		return this.compare(this.visualAnchor, this.cursor) <= 0 ? [this.visualAnchor, this.cursor] : [this.cursor, this.visualAnchor];
	}

	private selectedColsForLine(lineIndex: number): [number, number] | null {
		if (!this.visualMode) return null;
		const ordered = this.orderedSelection();
		if (!ordered) return null;
		const [start, end] = ordered;
		const lineLength = this.lines[lineIndex]?.text.length ?? 0;
		if (this.visualMode === "line") {
			return lineIndex >= start.line && lineIndex <= end.line ? [0, Math.max(1, lineLength)] : null;
		}
		if (lineIndex < start.line || lineIndex > end.line) return null;
		if (start.line === end.line) return [start.col, Math.min(lineLength, end.col) + 1];
		if (lineIndex === start.line) return [start.col, Math.max(1, lineLength)];
		if (lineIndex === end.line) return [0, Math.min(lineLength, end.col) + 1];
		return [0, Math.max(1, lineLength)];
	}

	private selectionStatus(): string {
		const ordered = this.orderedSelection();
		if (!ordered || !this.visualMode) return "cursor character will be yanked";
		const [start, end] = ordered;
		if (this.visualMode === "line") return `${end.line - start.line + 1} lines selected`;
		return start.line === end.line
			? `${Math.abs(end.col - start.col) + 1} chars selected`
			: `${end.line - start.line + 1} lines partially selected`;
	}

	private yank(): void {
		let text: string;
		let count: string;
		const ordered = this.orderedSelection();
		if (!ordered || !this.visualMode) {
			text = this.currentLineText();
			count = "1 line";
		} else if (this.visualMode === "line") {
			const [start, end] = ordered;
			text = this.lines.slice(start.line, end.line + 1).map((line) => line.raw).join("\n");
			count = `${end.line - start.line + 1} lines`;
		} else {
			const [start, end] = ordered;
			const parts: string[] = [];
			for (let lineIndex = start.line; lineIndex <= end.line; lineIndex++) {
				const raw = this.lines[lineIndex]?.raw ?? "";
				if (start.line === end.line) parts.push(raw.slice(start.col, end.col + 1));
				else if (lineIndex === start.line) parts.push(raw.slice(start.col));
				else if (lineIndex === end.line) parts.push(raw.slice(0, end.col + 1));
				else parts.push(raw);
			}
			text = parts.join("\n");
			count = start.line === end.line ? `${text.length} chars` : `${end.line - start.line + 1} lines`;
		}
		this.done([text, count]);
	}
}

async function runYank(ctx: any): Promise<void> {
	const lines = buildHistoryLines(ctx);
	const result = await ctx.ui.custom<string[] | null>((tui: any, theme: any, _keybindings: any, done: (value: string[] | null) => void) => {
		const pane = new HistoryYankPane(lines, theme, done);
		return {
			render: (width: number) => pane.render(width),
			invalidate: () => pane.invalidate(),
			handleInput: (data: string) => {
				pane.handleInput(data);
				tui.requestRender();
			},
		};
	});
	if (!result) return;

	const [text, count] = result;
	await copyToClipboard(text);
	ctx.ui.notify(`Yanked ${count} to clipboard`, "success");
}

export default function historyYank(pi: ExtensionAPI) {
	pi.registerCommand("yank", {
		description: "Vim-ish visual selection over message history, yank to clipboard",
		handler: async (_args, ctx) => runYank(ctx),
	});

	pi.registerShortcut("ctrl+shift+y", {
		description: "Open history visual yank mode",
		handler: async (ctx) => runYank(ctx),
	});
}
