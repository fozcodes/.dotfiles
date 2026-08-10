import { readFileSync } from "node:fs";
import { join } from "node:path";

type PackageMetadata = { identity?: string; description?: string };
type DetailResource = { id: string; path: string; details: string };
type DetailItem = { id: string; description?: string };

const isRecord = (value: unknown): value is Record<string, unknown> =>
	typeof value === "object" && value !== null && !Array.isArray(value);

const getNonEmptyString = (value: unknown) =>
	typeof value === "string" && value.trim() !== "" ? value.trim() : undefined;

export const getLeadingDocblock = (source: string) => {
	const match = source.match(/^\uFEFF?\s*\/\*\*([\s\S]*?)\*\//);
	const [, body] = match ?? [];
	if (body === undefined) return undefined;

	const details = body
		.split(/\r?\n/)
		.map((line) => line.replace(/^\s*\* ?/, "").trimEnd())
		.join("\n")
		.trim();
	return details === "" ? undefined : details;
};

const getDocblock = (extensionPath: string) => {
	try {
		return getLeadingDocblock(readFileSync(extensionPath, "utf8"));
	} catch {
		return undefined;
	}
};

const getPackageMetadata = (packageDir: string | undefined) => {
	if (!packageDir) return {};

	try {
		const manifest = JSON.parse(readFileSync(join(packageDir, "package.json"), "utf8")) as unknown;
		if (!isRecord(manifest)) return {};

		const name = getNonEmptyString(manifest.name);
		const version = getNonEmptyString(manifest.version);
		return {
			identity: name ? `${name}${version ? ` v${version}` : ""}` : undefined,
			description: getNonEmptyString(manifest.description),
		};
	} catch {
		return {};
	}
};

export const buildExtensionDetails = (
	entrypoint: string,
	docblock: string | undefined,
	packageMetadata: PackageMetadata,
) =>
	[packageMetadata.identity, packageMetadata.description ?? docblock, `Entrypoint: ${entrypoint}`]
		.filter(Boolean)
		.join("\n\n");

export const getExtensionDetails = (extensionPath: string, packageDir: string | undefined) =>
	buildExtensionDetails(
		extensionPath,
		getDocblock(extensionPath),
		getPackageMetadata(packageDir),
	);

export const toggleDetailDescriptions = (
	showingDetails: boolean,
	resources: DetailResource[],
	items: DetailItem[],
) => {
	const nextShowingDetails = !showingDetails;
	const detailsById = new Map(resources.map((resource) => [resource.id, resource.details]));
	const pathsById = new Map(resources.map((resource) => [resource.id, resource.path]));
	for (const item of items) {
		item.description = nextShowingDetails
			? detailsById.get(item.id) ?? item.description
			: pathsById.get(item.id) ?? item.description;
	}
	return nextShowingDetails;
};
