/**
 * User Message Border
 *
 * Adds the same light-purple left border used by the shaded input panel to
 * user messages in chat history.
 */

import { UserMessageComponent, type ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LEFT_BORDER = "\x1b[38;2;196;167;255m▌\x1b[39m";
const OSC_PREFIX_RE = /^(?:\x1b\][^\x07]*\x07)*/;

function addBorderAfterOscPrefix(line: string): string {
	const match = line.match(OSC_PREFIX_RE);
	const prefix = match?.[0] ?? "";
	return `${prefix}${LEFT_BORDER}${line.slice(prefix.length)}`;
}

export default function userMessageBorder(_pi: ExtensionAPI) {
	const proto = UserMessageComponent.prototype as any;
	if (proto.__leftPurpleBorderPatched) return;

	const originalRender = proto.render;
	proto.render = function patchedUserMessageRender(width: number): string[] {
		const lines = originalRender.call(this, Math.max(1, width - 1));
		return lines.map(addBorderAfterOscPrefix);
	};
	proto.__leftPurpleBorderPatched = true;
}
