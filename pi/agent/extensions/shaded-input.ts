/**
 * Shaded Input
 *
 * Makes the input editor render as a shaded panel so it visually separates from
 * the chat history, similar to opencode's bottom input area.
 */

import { CustomEditor, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const INPUT_BG = "#20242c";
const LEFT_BORDER = "#c4a7ff";
const PADDING_X = 2;
const PADDING_TOP = 1;
const PADDING_BOTTOM = 1;
const LEFT_BORDER_WIDTH = 1;

function hexToRgb(hex: string): [number, number, number] {
	const clean = hex.replace(/^#/, "");
	return [parseInt(clean.slice(0, 2), 16), parseInt(clean.slice(2, 4), 16), parseInt(clean.slice(4, 6), 16)];
}

function bgStart(hex: string): string {
	const [r, g, b] = hexToRgb(hex);
	return `\x1b[48;2;${r};${g};${b}m`;
}

function fgStart(hex: string): string {
	const [r, g, b] = hexToRgb(hex);
	return `\x1b[38;2;${r};${g};${b}m`;
}

function leftBorder(): string {
	return `${fgStart(LEFT_BORDER)}▌\x1b[39m`;
}

function stripEditorBorder(lines: string[]): string[] {
	if (lines.length <= 2) return lines;
	return lines.slice(1, -1).map((line) => {
		// Drop common box-drawing side borders while preserving inner ANSI/cursor markers.
		return line
			.replace(/^\s*(?:[│┃║]|\x1b\[[0-9;]*m[│┃║]\x1b\[[0-9;]*m?)\s?/, "")
			.replace(/\s?(?:[│┃║]|\x1b\[[0-9;]*m[│┃║]\x1b\[[0-9;]*m?)\s*$/, "");
	});
}

function shadeLine(line: string, width: number): string {
	const start = bgStart(INPUT_BG);
	const innerWidth = Math.max(0, width - LEFT_BORDER_WIDTH - PADDING_X * 2);
	const clipped = truncateToWidth(line, innerWidth, "");
	// Re-apply bg after reset/default-bg sequences inside editor-rendered ANSI, so
	// empty/untyped regions stay shaded instead of falling back to terminal black.
	const bgSafe = clipped.replace(/\x1b\[(?:0|49)m/g, (reset) => `${reset}${start}`);
	const paddedInner = bgSafe + " ".repeat(Math.max(0, innerWidth - visibleWidth(clipped)));
	return `${start}${leftBorder()}${" ".repeat(PADDING_X)}${paddedInner}${" ".repeat(PADDING_X)}\x1b[0m`;
}

function shadeBlank(width: number): string {
	return `${bgStart(INPUT_BG)}${leftBorder()}${" ".repeat(Math.max(0, width - LEFT_BORDER_WIDTH))}\x1b[0m`;
}

function withPanelPadding(lines: string[], width: number): string[] {
	return [
		...Array.from({ length: PADDING_TOP }, () => shadeBlank(width)),
		...lines,
		...Array.from({ length: PADDING_BOTTOM }, () => shadeBlank(width)),
		"",
	];
}

class ShadedEditor extends CustomEditor {
	render(width: number): string[] {
		const lines = stripEditorBorder(super.render(Math.max(1, width - LEFT_BORDER_WIDTH - PADDING_X * 2))).map((line) => shadeLine(line, width));
		return withPanelPadding(lines, width);
	}
}

class ShadedEditorWrapper {
	onSubmit?: (text: string) => void;
	onChange?: (text: string) => void;
	borderColor?: (str: string) => string;

	constructor(private readonly inner: any) {}

	get focused(): boolean {
		return this.inner.focused;
	}
	set focused(value: boolean) {
		this.inner.focused = value;
	}

	getText(): string {
		return this.inner.getText();
	}
	setText(text: string): void {
		this.inner.setText(text);
	}
	getExpandedText(): string {
		return this.inner.getExpandedText?.() ?? this.inner.getText();
	}
	insertTextAtCursor(text: string): void {
		this.inner.insertTextAtCursor?.(text);
	}
	addToHistory(text: string): void {
		this.inner.addToHistory?.(text);
	}
	setAutocompleteProvider(provider: any): void {
		this.inner.setAutocompleteProvider?.(provider);
	}
	setPaddingX(padding: number): void {
		this.inner.setPaddingX?.(padding);
	}
	setAutocompleteMaxVisible(maxVisible: number): void {
		this.inner.setAutocompleteMaxVisible?.(maxVisible);
	}
	handleInput(data: string): void {
		this.inner.onSubmit = this.onSubmit;
		this.inner.onChange = this.onChange;
		this.inner.handleInput(data);
	}
	render(width: number): string[] {
		this.inner.onSubmit = this.onSubmit;
		this.inner.onChange = this.onChange;
		const lines = stripEditorBorder(this.inner.render(Math.max(1, width - LEFT_BORDER_WIDTH - PADDING_X * 2))).map((line: string) => shadeLine(line, width));
		return withPanelPadding(lines, width);
	}
	invalidate(): void {
		this.inner.invalidate?.();
	}
}

export default function shadedInput(pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		const previous = ctx.ui.getEditorComponent();
		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			if (previous) return new ShadedEditorWrapper(previous(tui, theme, keybindings)) as any;
			return new ShadedEditor(tui, theme, keybindings);
		});
	});
}
