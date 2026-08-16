const MAIN = "main";

type PushInvocation = {
	command: string;
	remote: string | undefined;
	refspecs: string[];
	force: boolean;
	dryRun: boolean;
	all: boolean;
	tags: boolean;
};

function segments(command: string) {
	return command.split(/\s*(?:&&|\|\||[;|\n])\s*/).filter(Boolean);
}

function tokens(segment: string) {
	return segment.match(/(?:[^\s"']+|"[^"]*"|'[^']*')+/g)?.map((token) => token.replace(/^['"]|['"]$/g, "")) ?? [];
}

function pushArgs(segment: string) {
	const parts = tokens(segment);
	const git = parts.indexOf("git");
	if (git < 0) return undefined;

	let subcommand = git + 1;
	while (parts[subcommand]?.startsWith("-")) {
		const option = parts[subcommand];
		subcommand += option === "-C" || option === "--git-dir" || option === "--work-tree" ? 2 : 1;
	}
	if (parts[subcommand] !== "push") return undefined;
	return { command: segment.trim(), args: parts.slice(subcommand + 1) };
}

export function parsePushCommands(command: string) {
	const result: PushInvocation[] = [];
	for (const segment of segments(command)) {
		const parsed = pushArgs(segment);
		if (!parsed) continue;
		const positionals: string[] = [];
		let force = false;
		let dryRun = false;
		let all = false;
		let tags = false;
		let skipNext = false;
		for (const arg of parsed.args) {
			if (skipNext) {
				skipNext = false;
				continue;
			}
			if (arg === "-o" || arg === "--push-option") {
				skipNext = true;
				continue;
			}
			if (arg === "--dry-run" || arg === "-n") {
				dryRun = true;
				continue;
			}
			if (
				arg === "--force" ||
				arg === "--force-with-lease" ||
				arg.startsWith("--force-with-lease=") ||
				arg === "--force-if-includes" ||
				arg === "-f" ||
				(arg.startsWith("-") && !arg.startsWith("--") && arg.includes("f"))
			) {
				force = true;
				continue;
			}
			if (arg === "--all" || arg === "--mirror") {
				all = true;
				continue;
			}
			if (arg === "--tags") {
				tags = true;
				continue;
			}
			if (arg.startsWith("-")) continue;
			positionals.push(arg);
			if (arg.startsWith("+")) force = true;
		}
		result.push({
			command: parsed.command,
			remote: positionals[0],
			refspecs: positionals.slice(1),
			force,
			dryRun,
			all,
			tags,
		});
	}
	return result;
}

function destination(refspec: string, branch?: string) {
	const ref = refspec.startsWith("+") ? refspec.slice(1) : refspec;
	const colon = ref.indexOf(":");
	const target = colon < 0 ? ref : ref.slice(colon + 1) || ref.slice(0, colon);
	if (target === "HEAD") return branch;
	if (target.startsWith("refs/heads/")) return target.slice("refs/heads/".length);
	if (target.includes("*")) return MAIN;
	return target;
}

export function pushTargetsMain(command: string, branch?: string) {
	return parsePushCommands(command).some((push) => {
		if (push.dryRun) return false;
		if (push.all) return true;
		if (push.tags && push.refspecs.length === 0) return false;
		if (push.refspecs.length === 0) return branch === MAIN;
		return push.refspecs.some((refspec) => destination(refspec, branch) === MAIN);
	});
}
