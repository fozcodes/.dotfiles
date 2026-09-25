import type { Skill } from "@earendil-works/pi-coding-agent";

const nameColumnWidth = 16;
const sourceColumnWidth = 18;

const fitColumn = (value: string, width: number) =>
	(value.length <= width ? value : `${value.slice(0, width - 1)}…`).padEnd(width);

export const getSkillSource = (skill: Skill) => skill.sourceInfo.source;

export const formatSkillColumns = (skill: Skill) =>
	`${fitColumn(skill.name, nameColumnWidth)}  ${fitColumn(getSkillSource(skill), sourceColumnWidth)}`;

export const formatSkillColumnHeader = () =>
	`${fitColumn("Name", nameColumnWidth)}  ${fitColumn("Source", sourceColumnWidth)}`;

export const formatSkillDetails = (skill: Skill) =>
	[
		`Source: ${getSkillSource(skill)}`,
		`Origin: ${skill.sourceInfo.origin} (${skill.sourceInfo.scope})`,
		`Installed at: ${skill.sourceInfo.baseDir ?? skill.sourceInfo.path}`,
		`Skill file: ${skill.filePath}`,
		"",
		skill.description,
	].join("\n");
