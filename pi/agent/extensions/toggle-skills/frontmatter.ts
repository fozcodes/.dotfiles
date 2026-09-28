const disableModelInvocationKey = "disable-model-invocation";
const disableModelInvocationLine = /^disable-model-invocation\s*:[^\r\n]*(?:\r?\n|$)/gm;

const getFrontmatter = (source: string) => {
	const opening = /^---[ \t]*(\r?\n)/.exec(source);
	if (!opening) throw new Error("Skill has no frontmatter.");

	const start = opening[0].length;
	const closing = /^---[ \t]*(?:\r?\n|$)/m.exec(source.slice(start));
	if (!closing || closing.index === undefined) {
		throw new Error("Skill frontmatter has no closing delimiter.");
	}

	const end = start + closing.index;
	return { start, end, text: source.slice(start, end) };
};

export const setSkillModelInvocation = (source: string, disabled: boolean) => {
	const frontmatter = getFrontmatter(source);
	const withoutSetting = frontmatter.text.replace(disableModelInvocationLine, "");
	const lineEnding = source.includes("\r\n") ? "\r\n" : "\n";
	const setting = `${disableModelInvocationKey}: true${lineEnding}`;
	const updatedFrontmatter = disabled
		? `${withoutSetting}${withoutSetting.length === 0 || withoutSetting.endsWith("\n") ? "" : lineEnding}${setting}`
		: withoutSetting;

	return `${source.slice(0, frontmatter.start)}${updatedFrontmatter}${source.slice(frontmatter.end)}`;
};
