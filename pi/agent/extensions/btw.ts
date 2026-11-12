import type { AssistantMessage, Message, UserMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";

type Turn = { question: UserMessage; answer: AssistantMessage };
const historyKey = Symbol.for("dotfiles.btw.history");
const globalState = globalThis as typeof globalThis & { [historyKey]?: Map<string, Turn[]> };
const histories = globalState[historyKey] ??= new Map<string, Turn[]>();
const systemPrompt = "Answer the user's side question using the conversation as context. Be concise. Do not call tools.";

export function withoutToolDeclarations(messages: Message[]) {
  return messages.map((message) => {
    if (message.role !== "system") return message;
    const { toolsAdded: _added, toolsRemoved: _removed, ...rest } = message;
    return rest;
  });
}

export async function askBtw(
  ctx: ExtensionCommandContext,
  messages: Message[],
  history: Turn[],
  question: string,
  signal: AbortSignal,
) {
  if (!ctx.model) throw new Error("/btw requires an active model");
  const userMessage: UserMessage = {
    role: "user",
    content: [{ type: "text", text: question }],
    timestamp: Date.now(),
  };
  const response = await ctx.modelRegistry.streamSimple(
    ctx.model,
    {
      systemPrompt,
      messages: [...withoutToolDeclarations(messages), ...history.flatMap((turn) => [turn.question, turn.answer]), userMessage],
      tools: [],
    },
    { reasoning: ctx.thinkingLevel, signal, cacheRetention: "none" },
  ).result();
  if (signal.aborted || response.stopReason === "aborted") return undefined;
  if (response.stopReason === "error") throw new Error(response.errorMessage || "Unknown model error");
  const answer = response.content.filter((part) => part.type === "text").map((part) => part.text).join("\n").trim();
  if (!answer) throw new Error("/btw returned no text");
  return { question: userMessage, answer: response, text: answer };
}

async function showBtw(ctx: ExtensionCommandContext, question: string) {
  const [{ buildSessionContext, convertToLlm }, { matchesKey, wrapTextWithAnsi, truncateToWidth }] = await Promise.all([
    import("@earendil-works/pi-coding-agent"),
    import("@earendil-works/pi-tui"),
  ]);
  const messages = convertToLlm(buildSessionContext(ctx.sessionManager.getBranch()).messages);
  const sessionId = ctx.sessionManager.getSessionFile() ?? `memory:${ctx.sessionManager.getSessionId()}`;
  const history = histories.get(sessionId) ?? [];
  const controller = new AbortController();

  await ctx.ui.custom<void>((tui, theme, _keys, done) => {
    let text = "Thinking…";
    let scroll = 0;
    let closed = false;
    let displayedHistory = [...history];

    void askBtw(ctx, messages, history, question, controller.signal).then((result) => {
      if (!result || closed) return;
      histories.set(sessionId, [...(histories.get(sessionId) ?? []), { question: result.question, answer: result.answer }]);
      text = result.text;
      tui.requestRender();
    }).catch((error: unknown) => {
      if (closed) return;
      text = `/btw failed: ${error instanceof Error ? error.message : String(error)}`;
      tui.requestRender();
    });

    return {
      render(width: number) {
        const availableWidth = Math.max(1, width - 2);
        const lines = [
          theme.fg("accent", truncateToWidth(`/btw ${question.replace(/\s+/g, " ")}`, width)),
          ...displayedHistory.map((turn) => theme.fg("dim", truncateToWidth(`/btw ${turn.question.content.map((part) => part.type === "text" ? part.text : "").join("")}`, width))),
          "",
          ...text.split("\n").flatMap((line) => wrapTextWithAnsi(line || " ", availableWidth)).map((line) => `  ${line}`),
          "",
          theme.fg("dim", truncateToWidth("↑/↓ scroll · x clear history · Esc close", width)),
        ];
        const height = Math.max(1, Math.floor((tui.terminal.rows ?? 24) * 0.85));
        const excess = Math.max(0, lines.length - height);
        scroll = Math.min(scroll, excess);
        return lines.slice(excess - scroll, excess - scroll + height);
      },
      invalidate() {},
      handleInput(data: string) {
        if (matchesKey(data, "escape")) {
          closed = true;
          controller.abort();
          done();
        } else if (matchesKey(data, "up")) {
          scroll++;
          tui.requestRender();
        } else if (matchesKey(data, "down")) {
          scroll = Math.max(0, scroll - 1);
          tui.requestRender();
        } else if (data === "x") {
          histories.delete(sessionId);
          displayedHistory = [];
          tui.requestRender();
        }
      },
      dispose() {
        closed = true;
        controller.abort();
      },
    };
  }, { overlay: true, overlayOptions: { anchor: "bottom-center", width: "100%", maxHeight: "85%" } });
}

export default function btw(pi: ExtensionAPI) {
  pi.registerCommand("btw", {
    description: "Ask a side question without adding it to the conversation",
    async handler(args, ctx) {
      if (ctx.mode !== "tui") return ctx.ui.notify("/btw requires interactive mode", "error");
      const question = args.trim();
      if (!question) return ctx.ui.notify("Usage: /btw <question>", "warning");
      if (!ctx.model) return ctx.ui.notify("/btw requires an active model", "error");
      try {
        await showBtw(ctx, question);
      } catch (error) {
        ctx.ui.notify(`/btw failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    },
  });
}
