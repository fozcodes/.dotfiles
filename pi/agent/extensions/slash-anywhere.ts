import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type EditorRuntime = {
  state: {
    lines: string[];
    cursorLine: number;
    cursorCol: number;
  };
  handleSlashCommandCompletion: () => void;
  forceFileAutocomplete: (explicitTab?: boolean) => void;
};

type AutocompleteOptions = { force?: boolean; signal?: AbortSignal };
type AutocompleteItem = { value: string; label: string; description?: string };
type AutocompleteResult = { items: AutocompleteItem[]; prefix: string } | null;

type ProviderRuntime = {
  getSuggestions: (
    lines: string[],
    cursorLine: number,
    cursorCol: number,
    options: AutocompleteOptions,
  ) => Promise<AutocompleteResult>;
  applyCompletion: (
    lines: string[],
    cursorLine: number,
    cursorCol: number,
    item: AutocompleteItem,
    prefix: string,
  ) => { lines: string[]; cursorLine: number; cursorCol: number };
  shouldTriggerFileCompletion: (lines: string[], cursorLine: number, cursorCol: number) => boolean;
};

type PiTuiModule = {
  Editor: { prototype: Record<string, unknown> };
  CombinedAutocompleteProvider: { prototype: ProviderRuntime };
};

const slashTokenAtCursor = (textBeforeCursor: string) => {
  const match = textBeforeCursor.match(/(?:^|\s)(\/[^\n]*)$/);
  return match?.[1] ?? null;
};

const isCommandNamePrefix = (prefix: string) =>
  prefix.startsWith("/") && !prefix.slice(1).includes("/");

export default async function (pi: ExtensionAPI) {
  const tui = await import("/opt/homebrew/lib/node_modules/@earendil-works/pi-coding-agent/node_modules/@earendil-works/pi-tui/dist/index.js") as PiTuiModule;
  const editorPrototype = tui.Editor.prototype;

  editorPrototype.isSlashMenuAllowed = function () {
    return true;
  };

  editorPrototype.isAtStartOfMessage = function (this: EditorRuntime) {
    const currentLine = this.state.lines[this.state.cursorLine] ?? "";
    const beforeCursor = currentLine.slice(0, this.state.cursorCol);
    return /(?:^|\s)\/$/.test(beforeCursor);
  };

  editorPrototype.isInSlashCommandContext = function (textBeforeCursor: string) {
    return slashTokenAtCursor(textBeforeCursor) !== null;
  };

  editorPrototype.handleTabCompletion = function (this: EditorRuntime) {
    const currentLine = this.state.lines[this.state.cursorLine] ?? "";
    const beforeCursor = currentLine.slice(0, this.state.cursorCol);
    const slashToken = slashTokenAtCursor(beforeCursor);
    if (slashToken && !slashToken.slice(1).includes(" ")) {
      this.handleSlashCommandCompletion();
      return;
    }
    this.forceFileAutocomplete(true);
  };

  const providerPrototype = tui.CombinedAutocompleteProvider.prototype;
  const originalGetSuggestions = providerPrototype.getSuggestions;
  const originalApplyCompletion = providerPrototype.applyCompletion;
  const originalShouldTriggerFileCompletion = providerPrototype.shouldTriggerFileCompletion;

  providerPrototype.getSuggestions = async function (lines, cursorLine, cursorCol, options) {
    if (!options.force) {
      const currentLine = lines[cursorLine] ?? "";
      const textBeforeCursor = currentLine.slice(0, cursorCol);
      const slashToken = slashTokenAtCursor(textBeforeCursor);
      if (slashToken && !textBeforeCursor.startsWith("/")) {
        const fakeLines = [...lines];
        fakeLines[cursorLine] = slashToken;
        const result = await originalGetSuggestions.call(this, fakeLines, cursorLine, slashToken.length, options);
        if (result) return result;
      }
    }
    return originalGetSuggestions.call(this, lines, cursorLine, cursorCol, options);
  };

  providerPrototype.applyCompletion = function (lines, cursorLine, cursorCol, item, prefix) {
    if (isCommandNamePrefix(prefix)) {
      const currentLine = lines[cursorLine] ?? "";
      const beforePrefix = currentLine.slice(0, cursorCol - prefix.length);
      const afterCursor = currentLine.slice(cursorCol);
      const newLines = [...lines];
      newLines[cursorLine] = `${beforePrefix}/${item.value} ${afterCursor}`;
      return {
        lines: newLines,
        cursorLine,
        cursorCol: beforePrefix.length + item.value.length + 2,
      };
    }
    return originalApplyCompletion.call(this, lines, cursorLine, cursorCol, item, prefix);
  };

  providerPrototype.shouldTriggerFileCompletion = function (lines, cursorLine, cursorCol) {
    const currentLine = lines[cursorLine] ?? "";
    const textBeforeCursor = currentLine.slice(0, cursorCol);
    const slashToken = slashTokenAtCursor(textBeforeCursor);
    if (slashToken && !slashToken.slice(1).includes(" ")) return false;
    return originalShouldTriggerFileCompletion.call(this, lines, cursorLine, cursorCol);
  };

  pi.on("session_start", (_event, ctx) => {
    ctx.ui.notify("Slash menu enabled anywhere in input", "info");
  });
}
