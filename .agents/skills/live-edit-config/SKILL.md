---
name: live-edit-config
description: Wire an application config file (kdl, json, toml, lua, etc.) so it can be edited live from this repo without a NixOS rebuild. Use whenever adding a new app whose config the user wants to iterate on quickly — niri.kdl and noctalia-settings.json already follow this pattern. The technique is a home-manager mkOutOfStoreSymlink from ~/.config/<app>/<file> back to a real file under modules/, so edits in git (and writes by the app's own GUI, if any) round-trip without rebuilding.
---

# Live-edit config files

This repo wires app configs through `mkOutOfStoreSymlink` so config files can be edited in `modules/` (and apps with GUIs can write back) without running `nixos-rebuild` for every tweak. Existing examples: `modules/niri.kdl`, `modules/noctalia-settings.json`.

## Preconditions

- `/etc/nixos` is a symlink to the repo root (`readlink /etc/nixos` should print the repo path). If it isn't, this whole pattern fails — the symlink target won't resolve.
- The host has a `provides.<username>.homeManager` block in its host aspect (e.g. `modules/titan.nix`). That's where the `xdg.configFile` entry goes — it scopes the config to a specific user on a specific host via den's mutual-provider mechanism.

## Procedure

1. **Seed the config file in the repo.**
   - If the app already has an existing config at `~/.config/<app>/<file>`, copy it into `modules/<name>.<ext>` first so you don't wipe state on the next rebuild.
   - If starting fresh, create a minimal valid file (e.g. `{}` for JSON).

2. **`git add` the new file.** Flakes only see git-tracked files; an untracked config file is invisible to `nix flake check` and `nixos-rebuild`.

3. **In the host's `provides.<username>.homeManager` block, add:**

   ```nix
   xdg.configFile."<app>/<file>".source =
     config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/<name>.<ext>";
   ```

   The block already takes `{ config, ... }`; if writing a new block, make sure that argument is in scope.

4. **If the app ships a home-manager module with a declarative settings option** (e.g. noctalia's `programs.noctalia-shell.settings`), leave it at the default `{}` and do not set values. The HM module then skips creating `xdg.configFile."<app>/<file>"` itself, so the symlink declaration wins. Setting both will cause a merge conflict at evaluation time.

5. **Rebuild once** (`nh os switch` or `nixos-rebuild switch`). After this rebuild, future edits to `modules/<name>.<ext>` take effect on the app's next reload — no further rebuilds needed for config-only changes.

## Gotchas

- **Untracked file → cryptic eval error.** A reference to `den.aspects.<name>` for an unstaged module file fails with `attribute '<name>' missing`. Always `git add` before evaluating.
- **Don't mix with the HM module's settings option.** The symlink and the HM-generated file will fight. Pick one workflow per app.
- **GUI writebacks need user-writable target.** Because `/etc/nixos` is a symlink to a user-owned tree, the GUI can write through the symlink. If a host ever runs without that symlink setup, the file is read-only to non-root processes and GUI saves silently fail.
- **The file path matters.** `xdg.configFile."<app>/<file>"` is relative to `~/.config/`. Match the exact path the app reads from (consult the app's docs).

## When NOT to use this

- The config can be fully declarative as a nix attrset and the user is happy rebuilding. Use the HM module's settings option directly.
- The config is owned by a dotfile manager like chezmoi (see AGENTS.md). Leave it untouched.
