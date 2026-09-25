import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import type { Skill } from "@earendil-works/pi-coding-agent";

const lockFileName = ".skill-lock.json";
const publisherOverridesFileName = "skill-publishers.json";
const globalAgentsDirectory = join(homedir(), ".agents");
const globalAgentsSkillDirectory = join(globalAgentsDirectory, "skills");

const getAgentDirectory = () => {
	const configured = process.env.PI_CODING_AGENT_DIR?.trim();
	if (!configured) return join(homedir(), ".pi", "agent");
	if (configured === "~") return homedir();
	return configured.startsWith("~/") ? join(homedir(), configured.slice(2)) : configured;
};

type SkillLock = Record<string, string>;
type PublisherOverrides = Record<string, Record<string, string>>;

const isRecord = (value: unknown): value is Record<string, unknown> =>
	typeof value === "object" && value !== null && !Array.isArray(value);

export const parseSkillLock = (content: string) => {
	try {
		const parsed: unknown = JSON.parse(content);
		if (!isRecord(parsed) || !isRecord(parsed.skills)) return {};

		const publishers: SkillLock = {};
		for (const [name, value] of Object.entries(parsed.skills)) {
			if (isRecord(value) && typeof value.source === "string" && value.source !== "") {
				publishers[name] = value.source;
			}
		}
		return publishers;
	} catch {
		return {};
	}
};

export const parsePublisherOverrides = (content: string) => {
	try {
		const parsed: unknown = JSON.parse(content);
		if (!isRecord(parsed)) return {};

		const overrides: PublisherOverrides = {};
		for (const [installer, values] of Object.entries(parsed)) {
			if (!isRecord(values)) continue;
			const publishers: Record<string, string> = {};
			for (const [skill, publisher] of Object.entries(values)) {
				if (typeof publisher === "string" && publisher !== "") {
					publishers[skill] = publisher;
				}
			}
			if (Object.keys(publishers).length > 0) overrides[installer] = publishers;
		}
		return overrides;
	} catch {
		return {};
	}
};

const locks = new Map<string, Promise<SkillLock>>();

const loadLock = (path: string) => {
	const existing = locks.get(path);
	if (existing) return existing;

	const lock = readFile(path, "utf8").then(parseSkillLock).catch(() => ({}));
	locks.set(path, lock);
	return lock;
};

export const matchSkillPublisher = (
	skillName: string,
	currentContent: string,
	lockedContent: string,
	publishers: SkillLock,
) => (currentContent === lockedContent ? publishers[skillName] : undefined);

const publisherOverrides = readFile(
	join(getAgentDirectory(), publisherOverridesFileName),
	"utf8",
)
	.then(parsePublisherOverrides)
	.catch(() => ({}));

const getPublisherOverride = async (skillName: string, installer: string) =>
	(await publisherOverrides)[installer]?.[skillName];

const getPublisherFromAncestorLock = async (skill: Skill) => {
	let directory = dirname(skill.filePath);

	while (true) {
		const publishers = await loadLock(join(directory, lockFileName));
		const publisher = publishers[skill.name];
		if (publisher) return publisher;

		const parent = dirname(directory);
		if (parent === directory) return undefined;
		directory = parent;
	}
};

const getPublisherFromMatchingGlobalSkill = async (skill: Skill) => {
	const publishers = await loadLock(join(globalAgentsDirectory, lockFileName));
	if (!publishers[skill.name]) return undefined;

	try {
		const [currentContent, lockedContent] = await Promise.all([
			readFile(skill.filePath, "utf8"),
			readFile(join(globalAgentsSkillDirectory, skill.name, "SKILL.md"), "utf8"),
		]);
		return matchSkillPublisher(skill.name, currentContent, lockedContent, publishers);
	} catch {
		return undefined;
	}
};

export const getSkillPublisher = async (skill: Skill) => {
	const installer =
		(await getPublisherFromAncestorLock(skill)) ??
		(await getPublisherFromMatchingGlobalSkill(skill));
	return installer ? (await getPublisherOverride(skill.name, installer)) ?? installer : undefined;
};
