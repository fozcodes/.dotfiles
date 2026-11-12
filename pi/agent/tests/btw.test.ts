import assert from "node:assert/strict";
import test from "node:test";
import btw, { askBtw, withoutToolDeclarations } from "../extensions/btw.ts";

const model = { id: "test", provider: "test" };
const answer = { role: "assistant", content: [{ type: "text", text: "answer" }], stopReason: "stop" };

function harness(response = answer) {
  const requests: unknown[][] = [];
  const ctx = {
    model,
    thinkingLevel: "medium",
    modelRegistry: {
      streamSimple: (...args: unknown[]) => {
        requests.push(args);
        return { result: async () => response };
      },
    },
  };
  return { ctx, requests };
}

test("passes active model and thinking level with no tools and retains side history", async () => {
  const { ctx, requests } = harness();
  const branch = [{ role: "system", content: [{ type: "text", text: "system" }], toolsAdded: [{ name: "bash" }], toolsRemoved: ["read"] }];
  const history = [{ question: { role: "user", content: [{ type: "text", text: "earlier" }], timestamp: 1 }, answer }];
  const controller = new AbortController();
  const result = await askBtw(ctx as never, branch as never, history as never, "question", controller.signal);
  const [selectedModel, context, options] = requests[0] as [unknown, { messages: Array<{ role: string; toolsAdded?: unknown; toolsRemoved?: unknown }>; tools: unknown[] }, { reasoning: string; signal: AbortSignal; cacheRetention: string }];
  assert.equal(selectedModel, model);
  assert.equal(options.reasoning, "medium");
  assert.equal(options.signal, controller.signal);
  assert.equal(options.cacheRetention, "none");
  assert.deepEqual(context.tools, []);
  assert.deepEqual(context.messages.map((message) => message.role), ["system", "user", "assistant", "user"]);
  assert.equal(context.messages[0]?.toolsAdded, undefined);
  assert.equal(context.messages[0]?.toolsRemoved, undefined);
  assert.equal(result?.text, "answer");
});

test("preserves non-system messages when removing tool declarations", () => {
  const user = { role: "user", content: "hi" };
  assert.equal(withoutToolDeclarations([user] as never)[0], user);
});

test("reports provider errors and empty responses", async () => {
  const error = harness({ ...answer, stopReason: "error", errorMessage: "provider error" } as typeof answer);
  await assert.rejects(askBtw(error.ctx as never, [], [], "q", new AbortController().signal), /provider error/);
  const empty = harness({ ...answer, content: [] });
  await assert.rejects(askBtw(empty.ctx as never, [], [], "q", new AbortController().signal), /returned no text/);
});

test("does not return an answer after cancellation", async () => {
  const { ctx } = harness();
  const controller = new AbortController();
  controller.abort();
  assert.equal(await askBtw(ctx as never, [], [], "q", controller.signal), undefined);
});

test("registers the command and validates interactive mode, arguments and model", async () => {
  let handler: ((args: string, ctx: unknown) => Promise<void>) | undefined;
  btw({ registerCommand(name: string, command: { handler: typeof handler }) { assert.equal(name, "btw"); handler = command.handler; } } as never);
  assert.ok(handler);
  const notifications: string[] = [];
  const ctx = { mode: "rpc", model, ui: { notify: (message: string) => notifications.push(message) } };
  await handler("q", ctx);
  ctx.mode = "tui";
  await handler(" ", ctx);
  await handler("q", { ...ctx, model: undefined });
  assert.deepEqual(notifications, ["/btw requires interactive mode", "Usage: /btw <question>", "/btw requires an active model"]);
});
