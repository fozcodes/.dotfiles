import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import { parsePushCommands } from "./git-main-guard.logic.ts";

type GuardedPush = { command: string; remote?: string; force: boolean };

async function branchFor(pi: ExtensionAPI, cwd: string) {
	const result = await pi.exec("git", ["branch", "--show-current"], { cwd, timeout: 1500 });
	if (result.code !== 0) return undefined;
	return result.stdout.trim() || undefined;
}

function destination(refspec: string, branch?: string) {
	const ref = refspec.startsWith("+") ? refspec.slice(1) : refspec;
	const colon = ref.indexOf(":");
	const target = colon < 0 ? ref : ref.slice(colon + 1) || ref.slice(0, colon);
	if (target === "HEAD") return branch;
	if (target.startsWith("refs/heads/")) return target.slice("refs/heads/".length);
	if (target.includes("*")) return "main";
	return target;
}

async function guardedPushes(pi: ExtensionAPI, cwd: string, command: string) {
	const pushes = parsePushCommands(command).filter((push) => !push.dryRun);
	if (pushes.length === 0) return [];
	const needsBranch = pushes.some(
		(push) => push.refspecs.length === 0 || push.refspecs.some((ref) => ref === "HEAD" || ref.endsWith(":HEAD")),
	);
	const branch = needsBranch ? await branchFor(pi, cwd) : undefined;
	return pushes
		.filter((push) => {
			if (push.all) return true;
			if (push.tags && push.refspecs.length === 0) return false;
			if (push.refspecs.length === 0) return branch === "main";
			return push.refspecs.some((refspec) => destination(refspec, branch) === "main");
		})
		.map((push): GuardedPush => ({ command: push.command, remote: push.remote, force: push.force }));
}

export default function gitMainGuard(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (!isToolCallEventType("bash", event)) return;
		const pushes = await guardedPushes(pi, ctx.cwd, event.input.command);
		if (pushes.length === 0) return;
		if (!ctx.hasUI) {
			return { block: true, reason: "Push to main blocked: no UI is available for confirmation" };
		}
		const detail = pushes
			.map(({ command, remote, force }) => `${force ? "FORCE " : ""}${remote ? `${remote}: ` : ""}${command}`)
			.join("\n");
		const ok = await ctx.ui.confirm("Push to main?", `${detail}\n\nThis updates the protected main branch. Continue?`);
		if (!ok) return { block: true, reason: "Push to main cancelled by user" };
	});
}
