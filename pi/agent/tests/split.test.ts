import assert from "node:assert/strict";
import test from "node:test";
import { initTheme, UserMessageSelectorComponent } from "@earendil-works/pi-coding-agent";

initTheme("dark");

const stripAnsi = (text: string) => text.replace(/\x1B\[[0-?]*[ -/]*[@-~]/g, "");

test("uses Pi's fork selector with a moving highlighted message", () => {
	let selectedEntryId: string | undefined;
	const selector = new UserMessageSelectorComponent(
		[
			{ id: "first", text: "First message" },
			{ id: "second", text: "Second message" },
		],
		(entryId) => {
			selectedEntryId = entryId;
		},
		() => undefined,
		"second",
	);
	const messageList = selector.getMessageList();

	assert.match(stripAnsi(messageList.render(80).join("\n")), /› Second message/);
	messageList.handleInput("\x1b[A");
	assert.match(stripAnsi(messageList.render(80).join("\n")), /› First message/);
	messageList.handleInput("\r");

	assert.equal(selectedEntryId, "first");
});
