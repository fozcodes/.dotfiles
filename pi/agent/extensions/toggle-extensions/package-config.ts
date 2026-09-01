import type { PackageSource } from "@earendil-works/pi-coding-agent";

export const projectLocalPackageSources = new Set(["npm:pi-subagents"]);

const projectLocalPackageDefaults = {
	"npm:pi-subagents": {
		skills: ["skills/**"],
		prompts: ["prompts/**"],
	},
};

const stripPrefix = (value: string) =>
	value.startsWith("!") || value.startsWith("+") || value.startsWith("-")
		? value.slice(1)
		: value;

const getPackageSource = (pkg: PackageSource) =>
	typeof pkg === "string" ? pkg : pkg.source;

const withResourceFilter = (current: string[], pattern: string, enabled: boolean) => {
	const updated = current.filter((value) => stripPrefix(value) !== pattern);
	updated.push(`${enabled ? "+" : "-"}${pattern}`);
	return updated;
};

export const isProjectLocalPackage = (source: string) =>
	projectLocalPackageSources.has(source);

export const updateProjectPackageExtension = (
	packages: PackageSource[],
	source: string,
	pattern: string,
	enabled: boolean,
) => {
	const index = packages.findIndex((pkg) => getPackageSource(pkg) === source);
	const existing = index < 0 ? undefined : packages[index];
	const pkg =
		typeof existing === "string" || existing === undefined
			? { source, autoload: false }
			: { ...existing, autoload: false };
	const extensions = withResourceFilter(pkg.extensions ?? [], pattern, enabled);
	const updated = [...packages];
	const defaults = projectLocalPackageDefaults[source as keyof typeof projectLocalPackageDefaults];
	const configured = {
		...pkg,
		extensions,
		skills: pkg.skills ?? defaults?.skills,
		prompts: pkg.prompts ?? defaults?.prompts,
	};

	if (index < 0) {
		updated.push(configured);
	} else {
		updated[index] = configured;
	}

	return updated;
};
