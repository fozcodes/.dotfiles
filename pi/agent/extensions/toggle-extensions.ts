import { dirname, join, relative } from "node:path";
import type {
	ExtensionAPI,
	PackageSource,
	ResolvedResource,
	SettingsManager,
} from "@earendil-works/pi-coding-agent";
import {
	DefaultPackageManager,
	getAgentDir,
	getSettingsListTheme,
	SettingsManager as PiSettingsManager,
} from "@earendil-works/pi-coding-agent";
import { Container, type SettingItem, SettingsList } from "@earendil-works/pi-tui";

type ExtensionResource = ResolvedResource & { id: string; label: string };
type ResourceType = "extensions";

const stripPrefix = (value: string) =>
	value.startsWith("!") || value.startsWith("+") || value.startsWith("-")
		? value.slice(1)
		: value;

const getPackageSource = (pkg: PackageSource) =>
	typeof pkg === "string" ? pkg : pkg.source;

const withResourceFilter = (
	current: string[],
	pattern: string,
	enabled: boolean,
) => {
	const updated = current.filter((value) => stripPrefix(value) !== pattern);
	updated.push(`${enabled ? "+" : "-"}${pattern}`);
	return updated;
};

const getDisplayScope = (resource: ExtensionResource) =>
	`${resource.metadata.source} (${resource.metadata.scope})`;

const getPattern = (resource: ExtensionResource, cwd: string, agentDir: string) => {
	if (resource.metadata.origin === "package") {
		return relative(resource.metadata.baseDir ?? dirname(resource.path), resource.path);
	}

	const baseDir =
		resource.metadata.baseDir ??
		(resource.metadata.scope === "project" ? join(cwd, ".pi") : agentDir);
	return relative(baseDir, resource.path);
};

const updateTopLevelExtension = (
	settingsManager: SettingsManager,
	resource: ExtensionResource,
	cwd: string,
	agentDir: string,
	enabled: boolean,
) => {
	const settings =
		resource.metadata.scope === "project"
			? settingsManager.getProjectSettings()
			: settingsManager.getGlobalSettings();
	const current = settings.extensions ?? [];
	const updated = withResourceFilter(
		current,
		getPattern(resource, cwd, agentDir),
		enabled,
	);

	if (resource.metadata.scope === "project") {
		settingsManager.setProjectExtensionPaths(updated);
		return;
	}
	settingsManager.setExtensionPaths(updated);
};

const updatePackageExtension = (
	settingsManager: SettingsManager,
	resource: ExtensionResource,
	cwd: string,
	agentDir: string,
	enabled: boolean,
) => {
	const settings =
		resource.metadata.scope === "project"
			? settingsManager.getProjectSettings()
			: settingsManager.getGlobalSettings();
	const packages = [...(settings.packages ?? [])];
	const index = packages.findIndex(
		(pkg) => getPackageSource(pkg) === resource.metadata.source,
	);
	if (index < 0) return;

	const existing = packages[index];
	if (existing === undefined) return;

	const pkg = typeof existing === "string" ? { source: existing } : { ...existing };
	const current = pkg.extensions ?? [];
	const updated = withResourceFilter(
		current,
		getPattern(resource, cwd, agentDir),
		enabled,
	);
	pkg.extensions = updated.length > 0 ? updated : undefined;

	const hasFilters = ["extensions", "skills", "prompts", "themes"].some(
		(key) => pkg[key as ResourceType | "skills" | "prompts" | "themes"] !== undefined,
	);
	packages[index] = hasFilters ? pkg : pkg.source;

	if (resource.metadata.scope === "project") {
		settingsManager.setProjectPackages(packages);
		return;
	}
	settingsManager.setPackages(packages);
};

const updateExtension = (
	settingsManager: SettingsManager,
	resource: ExtensionResource,
	cwd: string,
	agentDir: string,
	enabled: boolean,
) => {
	if (resource.metadata.origin === "package") {
		updatePackageExtension(settingsManager, resource, cwd, agentDir, enabled);
		return;
	}
	updateTopLevelExtension(settingsManager, resource, cwd, agentDir, enabled);
};

const buildResources = (extensions: ResolvedResource[]) =>
	extensions
		.map((extension, index): ExtensionResource => {
			const resource = { ...extension, id: String(index), label: "" };
			return {
				...resource,
				label: `${getDisplayScope(resource)}: ${relative(extension.metadata.baseDir ?? dirname(extension.path), extension.path)}`,
			};
		})
		.sort((a, b) => a.label.localeCompare(b.label));

export default function toggleExtensions(pi: ExtensionAPI) {
	pi.registerCommand("extensions", {
		description: "Enable/disable installed extensions",
		handler: async (_args, ctx) => {
			const agentDir = getAgentDir();
			const settingsManager = PiSettingsManager.create(ctx.cwd, agentDir);
			const packageManager = new DefaultPackageManager({
				cwd: ctx.cwd,
				agentDir,
				settingsManager,
			});
			const resolved = await packageManager.resolve(async () => "skip");
			const resources = buildResources(resolved.extensions);
			const byId = new Map(resources.map((resource) => [resource.id, resource]));

			if (resources.length === 0) {
				ctx.ui.notify("No extensions found.", "info");
				return;
			}

			await ctx.ui.custom((tui, theme, _kb, done) => {
				const items: SettingItem[] = resources.map((resource) => ({
					id: resource.id,
					label: resource.label,
					description: resource.path,
					currentValue: resource.enabled ? "enabled" : "disabled",
					values: ["enabled", "disabled"],
				}));

				const container = new Container();
				container.addChild(
					new (class {
						render() {
							return [
								theme.fg("accent", theme.bold("Extension Configuration")),
								theme.fg("muted", "Toggle entries, Esc to close. Changes apply after reload."),
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
						const resource = byId.get(id);
						if (!resource) return;
						resource.enabled = value === "enabled";
						updateExtension(
							settingsManager,
							resource,
							ctx.cwd,
							agentDir,
							resource.enabled,
						);
						void settingsManager.flush();
					},
					() => done(undefined),
					{ enableSearch: true },
				);
				container.addChild(settingsList);

				return {
					render: (width: number) => container.render(width),
					invalidate: () => container.invalidate(),
					handleInput: (data: string) => {
						settingsList.handleInput?.(data);
						tui.requestRender();
					},
				};
			});

			await settingsManager.flush();
			const reload = await ctx.ui.confirm(
				"Reload Pi?",
				"Extension changes require /reload or restart. Reload now?",
			);
			if (reload) {
				await ctx.reload();
			}
		},
	});
}
