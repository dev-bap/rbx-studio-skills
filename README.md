# Roblox Studio skills

The skills Roblox Studio's Assistant ships with, archived verbatim and refreshed
with each Studio release. Git history follows how they change.

Each skill is a folder under `skills/`. Its `SKILL.md` starts with the name and
description Studio uses to pick it; the other files are the references and
commands it loads on demand. `skills/STUDIO_VERSION` names the release they come
from.

## What an agent actually gets

A release ships more skills than the Studio MCP server serves: 23 against 13 in
Studio 0.747, most likely held back by feature flags. Call the MCP `list_skills`
tool to see which ones are live for an account.

The shipped text also keeps `{ToolNames.*}` placeholders, which Studio replaces
with its tool names (`execute_luau`, `script_read`...) when it serves a skill.
Apart from those, what the MCP returns matches these files character for
character.

## How it is extracted

`tools/extract.luau`, run with [Lune](https://github.com/lune-org/lune) from the
repository root:

```powershell
lune run tools/extract.luau
```

1. It asks `clientsettings.roblox.com` which Studio version is live.
2. It downloads that release's `BuiltInStandalonePlugins.zip` from the public
   setup CDN, no account needed, and takes `Assistant.rbxm` out of it.
3. It rewrites `skills/` with every `StringValue` under
   `Assistant/Packages/_Index/AssistantSkills/AssistantSkills`.

`skills/` mirrors one release exactly, so a file a release drops disappears; git
keeps the history. `.github/workflows/extract.yml` runs the script once a day
and commits when something changed; it can also be started by hand from the
Actions tab.

The two files in `tools/lib/` read the zip and model formats, because Lune
cannot: it has no zip reader, and `roblox.deserializeModel` refuses
`Assistant.rbxm` (`Property BoolValue.Tags should be SharedString`), which is
also why Studio calls the file corrupted when it is imported.

## Ownership

The skill texts are written by Roblox and remain theirs. This repository only
archives them so their changes can be followed over time.
