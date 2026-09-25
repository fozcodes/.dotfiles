/**
 * Skill configuration
 *
 * Provides `/skills` to inspect every loaded skill and toggle model invocation.
 */
import { readFile, writeFile } from "node:fs/promises";
import { relative } from "node:path";
import { getSettingsListTheme, type ExtensionAPI, type Skill } from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList } from "@earendil-works/pi-tui";
import {
	formatSkillColumnHeader,
	formatSkillColumns,
	formatSkillDetails,
} from "./toggle-skills/display.ts";
import { getSkillPublisher } from "./toggle-skills/provenance.ts";
import { setSkillModelInvocation } from "./toggle-skills/frontmatter.ts";

type SkillResource = Skill & {
	id: string;
	label: string;
	publisher: string;
};

const buildResources = async (skills: Skill[]) =>
	(
		await Promise.all(
			skills.map(async (skill) => {
				const publisher = (await getSkillPublisher(skill)) ?? "unattributed";
				return {
					...skill,
					id: skill.filePath,
					label: formatSkillColumns(skill, publisher),
					publisher,
				};
			}),
		)
	).sort((left, right) => left.label.localeCompare(right.label));

const modeForValue = (value: string) => value === "manual-only";

const updateSkill = async (skill: SkillResource, disabled: boolean) => {
	const source = await readFile(skill.filePath, "utf8");
	const updated = setSkillModelInvocation(source, disabled);
	if (updated !== source) await writeFile(skill.filePath, updated, "utf8");
};

export default function toggleSkills(pi: ExtensionAPI) {
	pi.registerCommand("skills", {
		description: "List skills and toggle model invocation",
		handler: async (_args, ctx) => {
			if (!ctx.hasUI) {
				ctx.ui.notify("/skills requires interactive mode.", "error");
				return;
			}

			const resources = await buildResources(ctx.getSystemPromptOptions().skills);
			if (resources.length === 0) {
				ctx.ui.notify("No skills found.", "info");
				return;
			}

			const byId = new Map(resources.map((resource) => [resource.id, resource]));
			let updates = Promise.resolve();
			let changed = false;

			await ctx.ui.custom((tui, theme, _keybindings, done) => {
				const items: SettingItem[] = resources.map((resource) => ({
					id: resource.id,
					label: resource.label,
					description: formatSkillDetails(resource, resource.publisher),
					currentValue: resource.disableModelInvocation ? "manual-only" : "agent-invocable",
					values: ["agent-invocable", "manual-only"],
				}));

				const container = new Container();
				container.addChild(
					new (class {
						render() {
							return [
								theme.fg("accent", theme.bold("Skill Configuration")),
								theme.fg(
									"muted",
									"Publisher identifies the skill's author repository. Changes apply after reload.",
								),
								formatSkillColumnHeader(),
								"",
							];
						}
						invalidate() {}
					})(),
				);

				const settingsList = new SettingsList(
					items,
					Math.min(items.length + 2, 18),
					getSettingsListTheme(),
					(id, value) => {
						const skill = byId.get(id);
						if (!skill) return;

						const disabled = modeForValue(value);
						if (skill.disableModelInvocation === disabled) return;
						skill.disableModelInvocation = disabled;
						changed = true;
						updates = updates
							.then(() => updateSkill(skill, disabled))
							.catch((error: unknown) => {
								ctx.ui.notify(
									`Could not update ${relative(ctx.cwd, skill.filePath)}: ${error instanceof Error ? error.message : String(error)}`,
									"error",
								);
							});
					},
					() => done(undefined),
					{ enableSearch: true },
				);
				container.addChild(settingsList);

				return {
					render: (width: number) => container.render(width),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => settingsList.handleInput?.(data),
				};
			});

			await updates;
			if (changed) await ctx.reload();
		},
	});
}
