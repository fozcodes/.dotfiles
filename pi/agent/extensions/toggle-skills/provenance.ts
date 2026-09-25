import { readFile } from "node:fs/promises";
import { dirname, join } from "node:path";
import type { Skill } from "@earendil-works/pi-coding-agent";

const lockFileName = ".skill-lock.json";

type SkillLock = Record<string, string>;

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

const locks = new Map<string, Promise<SkillLock>>();

const loadLock = (path: string) => {
	const existing = locks.get(path);
	if (existing) return existing;

	const lock = readFile(path, "utf8").then(parseSkillLock).catch(() => ({}));
	locks.set(path, lock);
	return lock;
};

export const getSkillPublisher = async (skill: Skill) => {
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
