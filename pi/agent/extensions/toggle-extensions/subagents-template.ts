import { existsSync, readFileSync, writeFileSync } from "node:fs";

type Json = boolean | Json[] | JsonObject | null | number | string;
type JsonObject = { [key: string]: Json };

const defaultSubagents = {
	watchdog: {
		enabled: true,
		main: {
			model: "openai-codex/gpt-5.6-luna",
			thinking: "medium",
		},
	},
};

const isJsonObject = (value: unknown): value is JsonObject =>
	typeof value === "object" && value !== null && !Array.isArray(value);

const readSettings = (settingsPath: string) => {
	if (!existsSync(settingsPath)) return {};

	const parsed: Json = JSON.parse(readFileSync(settingsPath, "utf8")) as Json;
	if (!isJsonObject(parsed)) {
		throw new Error(`${settingsPath} must contain a JSON object`);
	}
	return parsed;
};

export const ensureProjectSubagentsTemplate = (settingsPath: string) => {
	const settings = readSettings(settingsPath);
	if (isJsonObject(settings.subagents)) return false;

	writeFileSync(
		settingsPath,
		`${JSON.stringify({ ...settings, subagents: defaultSubagents }, null, 2)}\n`,
		"utf8",
	);
	return true;
};
