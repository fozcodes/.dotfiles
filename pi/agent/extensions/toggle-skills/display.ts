import { homedir } from "node:os";
import type { Skill } from "@earendil-works/pi-coding-agent";

const nameColumnWidth = 14;
const publisherColumnWidth = 20;

const fitColumn = (value: string, width: number) =>
	(value.length <= width ? value : `${value.slice(0, width - 1)}…`).padEnd(width);

const abbreviateHome = (path: string) => {
	const home = homedir();
	return path === home ? "~" : path.startsWith(`${home}/`) ? `~/${path.slice(home.length + 1)}` : path;
};

export const getSkillSource = (skill: Skill) =>
	skill.sourceInfo.source === "auto"
		? abbreviateHome(skill.sourceInfo.baseDir ?? skill.baseDir)
		: skill.sourceInfo.source;

export const formatSkillColumns = (skill: Skill, publisher: string) =>
	`${fitColumn(skill.name, nameColumnWidth)}  ${fitColumn(publisher, publisherColumnWidth)}`;

export const formatSkillColumnHeader = () =>
	`${fitColumn("Name", nameColumnWidth)}  ${fitColumn("Publisher", publisherColumnWidth)}`;

export const formatSkillDetails = (skill: Skill, publisher: string) =>
	[
		`Publisher: ${publisher}`,
		`Source: ${getSkillSource(skill)}`,
		`Origin: ${skill.sourceInfo.origin} (${skill.sourceInfo.scope})`,
		`Installed at: ${skill.sourceInfo.baseDir ?? skill.sourceInfo.path}`,
		`Skill file: ${skill.filePath}`,
		"",
		skill.description,
	].join("\n");
