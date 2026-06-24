import fs from "node:fs";
import path from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { getAgentDir } from "@earendil-works/pi-coding-agent";

type ThinkingLevel = "off" | "minimal" | "low" | "medium" | "high" | "xhigh";

type ModelProfile = {
  provider?: string;
  model?: string;
  thinkingLevel?: ThinkingLevel;
};

type LoadedProfile = {
  path: string;
  profile: ModelProfile;
};

type DefaultSettingsKey = "defaultProvider" | "defaultModel" | "defaultThinkingLevel";

type DefaultSettingsSnapshot = {
  path: string;
  existed: boolean;
  present: Set<DefaultSettingsKey>;
  values: Partial<Record<DefaultSettingsKey, unknown>>;
};

const modelDefaultSettingsKeys: DefaultSettingsKey[] = [
  "defaultProvider",
  "defaultModel",
];

const defaultSettingsKeys: DefaultSettingsKey[] = [
  ...modelDefaultSettingsKeys,
  "defaultThinkingLevel",
];

const thinkingLevels = new Set<ThinkingLevel>([
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
]);

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isThinkingLevel(value: unknown): value is ThinkingLevel {
  return typeof value === "string" && thinkingLevels.has(value as ThinkingLevel);
}

function getSettingsFilePath() {
  return path.join(getAgentDir(), "settings.json");
}

function readJsonObject(filePath: string) {
  const parsed: unknown = JSON.parse(fs.readFileSync(filePath, "utf-8"));
  if (!isRecord(parsed)) {
    throw new Error(`${filePath} must contain a JSON object`);
  }
  return parsed;
}

function snapshotDefaultSettings(): DefaultSettingsSnapshot {
  const settingsPath = getSettingsFilePath();
  const existed = fs.existsSync(settingsPath);
  const current = existed ? readJsonObject(settingsPath) : {};
  const present = new Set<DefaultSettingsKey>();
  const values: Partial<Record<DefaultSettingsKey, unknown>> = {};

  for (const key of defaultSettingsKeys) {
    if (Object.prototype.hasOwnProperty.call(current, key)) {
      present.add(key);
      values[key] = current[key];
    }
  }

  return { path: settingsPath, existed, present, values };
}

function restoreDefaultSettings(
  snapshot: DefaultSettingsSnapshot,
  keys: DefaultSettingsKey[] = defaultSettingsKeys,
) {
  if (!fs.existsSync(snapshot.path)) {
    return;
  }

  const current = readJsonObject(snapshot.path);
  for (const key of keys) {
    if (snapshot.present.has(key)) {
      current[key] = snapshot.values[key];
    } else {
      delete current[key];
    }
  }

  if (!snapshot.existed && Object.keys(current).length === 0) {
    fs.unlinkSync(snapshot.path);
    return;
  }

  fs.writeFileSync(snapshot.path, `${JSON.stringify(current, null, 2)}\n`, "utf-8");
}

function restoreDefaultsSoon(snapshot: DefaultSettingsSnapshot) {
  setTimeout(() => {
    try {
      restoreDefaultSettings(snapshot, modelDefaultSettingsKeys);
    } catch {
      // Ignore background restore errors. /model-profile reports foreground errors.
    }
  }, 100);
}

function parseProfile(content: string, sourcePath: string) {
  const parsed: unknown = JSON.parse(content);
  if (!isRecord(parsed)) {
    throw new Error(`${sourcePath} must contain a JSON object`);
  }

  const profile: ModelProfile = {};

  if (parsed.provider !== undefined) {
    if (typeof parsed.provider !== "string" || parsed.provider.trim() === "") {
      throw new Error(`${sourcePath}: provider must be a non-empty string`);
    }
    profile.provider = parsed.provider.trim();
  }

  if (parsed.model !== undefined) {
    if (typeof parsed.model !== "string" || parsed.model.trim() === "") {
      throw new Error(`${sourcePath}: model must be a non-empty string`);
    }
    profile.model = parsed.model.trim();
  }

  if (parsed.thinkingLevel !== undefined) {
    if (!isThinkingLevel(parsed.thinkingLevel)) {
      throw new Error(
        `${sourcePath}: thinkingLevel must be one of ${Array.from(thinkingLevels).join(", ")}`,
      );
    }
    profile.thinkingLevel = parsed.thinkingLevel;
  }

  return profile;
}

function findProfile(cwd: string): LoadedProfile | undefined {
  let dir = path.resolve(cwd);

  while (true) {
    const profilePath = path.join(dir, ".pi", "model-profile.json");
    if (fs.existsSync(profilePath)) {
      const content = fs.readFileSync(profilePath, "utf-8");
      return { path: profilePath, profile: parseProfile(content, profilePath) };
    }

    const parent = path.dirname(dir);
    if (parent === dir) return undefined;
    dir = parent;
  }
}

function formatProfile(loaded: LoadedProfile) {
  const { provider, model, thinkingLevel } = loaded.profile;
  const parts = [
    provider && model ? `${provider}/${model}` : undefined,
    thinkingLevel ? `thinking:${thinkingLevel}` : undefined,
  ].filter((part): part is string => Boolean(part));

  return `${parts.join(" ") || "no changes"} (${loaded.path})`;
}

async function applyProfile(loaded: LoadedProfile, pi: ExtensionAPI, ctx: ExtensionContext) {
  const { provider, model, thinkingLevel } = loaded.profile;
  const messages: string[] = [];

  if (provider !== undefined || model !== undefined) {
    if (provider === undefined || model === undefined) {
      ctx.ui.notify(
        `Model profile needs both provider and model: ${loaded.path}`,
        "warning",
      );
    } else {
      const target = ctx.modelRegistry.find(provider, model);
      if (!target) {
        ctx.ui.notify(`Model profile not found: ${provider}/${model}`, "warning");
      } else {
        const success = await pi.setModel(target);
        if (success) {
          messages.push(`${provider}/${model}`);
        } else {
          ctx.ui.notify(
            `Model profile has no API key: ${provider}/${model}`,
            "warning",
          );
        }
      }
    }
  }

  if (thinkingLevel !== undefined) {
    pi.setThinkingLevel(thinkingLevel);
    messages.push(`thinking:${thinkingLevel}`);
  }

  return messages;
}

async function loadAndApplyProfile(pi: ExtensionAPI, ctx: ExtensionContext, notify: boolean) {
  let loaded: LoadedProfile | undefined;

  try {
    loaded = findProfile(ctx.cwd);
  } catch (error) {
    ctx.ui.notify(error instanceof Error ? error.message : String(error), "error");
    return;
  }

  if (!loaded) {
    if (notify) ctx.ui.notify("No .pi/model-profile.json found in parent dirs", "info");
    return;
  }

  const settingsSnapshot = snapshotDefaultSettings();
  const applied = await applyProfile(loaded, pi, ctx);
  try {
    restoreDefaultSettings(settingsSnapshot);
  } catch (error) {
    ctx.ui.notify(
      `Applied profile but failed to restore global model defaults: ${error instanceof Error ? error.message : String(error)}`,
      "warning",
    );
  }

  if (notify) {
    ctx.ui.notify(
      applied.length > 0
        ? `Applied model profile without changing global defaults: ${formatProfile(loaded)}`
        : `Loaded model profile; no changes applied: ${loaded.path}`,
      "info",
    );
  }
}

export default function modelProfile(pi: ExtensionAPI) {
  let protectedDefaults: DefaultSettingsSnapshot | undefined;

  pi.on("session_start", async (_event, ctx) => {
    try {
      protectedDefaults = snapshotDefaultSettings();
    } catch (error) {
      ctx.ui.notify(
        `Model default guard disabled: ${error instanceof Error ? error.message : String(error)}`,
        "warning",
      );
    }

    await loadAndApplyProfile(pi, ctx, false);
  });

  pi.on("model_select", (event) => {
    if (event.source === "restore" || !protectedDefaults) return;
    restoreDefaultsSoon(protectedDefaults);
  });

  pi.registerCommand("model-profile", {
    description: "Reapply nearest parent .pi/model-profile.json",
    handler: async (_args, ctx) => {
      await loadAndApplyProfile(pi, ctx, true);
    },
  });
}
