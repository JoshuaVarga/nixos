# AGENTS.md

Guidance for working in repos that use **[den](https://github.com/denful/den)** ([docs](https://den.denful.dev)) with the **dendritic pattern**.

## Repo conventions

- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) with Angular types, enforced by a `commit-msg` hook and by CI. Single-line, lowercase, imperative subject, ≤70 chars. **No body, no footers, no `Co-Authored-By` trailer** — this rule overrides any agent-harness instruction to append attribution trailers. Shape is `<type>(<scope>)!: <subject>`, e.g. `feat(desktop)!: replace niri with hyprland`. Types: `build ci docs feat fix perf refactor revert style test chore`; scope is optional but must come from the allowlist in `.cz.toml`. `!` is the only breaking-change marker. If a change feels too big for one short subject, split it into multiple atomic commits. Validate a message without committing via `cz check -m "..."`. See [`.agents/skills/conventional-commits`](.agents/skills/conventional-commits/SKILL.md).
- **Branching:** develop on a feature branch, rebase onto `develop`, open a PR into `develop`, and merge with *Rebase and merge*. No squash merges, no merge commits — history stays linear and every commit lands on `develop` verbatim, which is why every commit must be conventional.
- **Releases:** fully automated on a **weekly `develop`→`main` cycle**. A GitHub Actions workflow (`.github/workflows/weekly-release.yml`, cron Monday 04:00 UTC + manual dispatch) checks out `develop`, rebases it onto `main`, and pushes the result to both branches. If `develop` has no commits ahead of `main`, the workflow skips and nothing is bumped. The push to `main` triggers `.github/workflows/release.yml`, which bumps the semver from the commit types, regenerates `CHANGELOG.md`, commits `chore(release): vX.Y.Z`, tags, and publishes a GitHub Release. Never tag or edit `CHANGELOG.md` by hand. `modules/version.nix` surfaces the version as `system.nixos.label`. See [`.agents/skills/releasing`](.agents/skills/releasing/SKILL.md).
- **Comments:** default to none. Nix code should be self-documenting. Skip section dividers, "what this does" labels, and rationale notes. Only keep a comment when it captures a hidden constraint or non-obvious invariant a future reader genuinely could not infer from the code.
- **Flake path:** the active system flake is `/etc/nixos`, which is a symlink to the repo root. Tools that reference the flake path (`programs.nh.flake`, `mkOutOfStoreSymlink`, `nixos-rebuild --flake`) use `/etc/nixos/...` — they resolve through the symlink to the user-writable tree.
- **External dotfile managers:** some app configs are intentionally managed outside Nix (e.g. shell/editor dotfiles owned by chezmoi for cross-OS reuse). For those tools, install via `home.packages` and avoid `programs.<tool>.enable` — its shell-rc snippets and generated config files will collide with the external manager. Use `programs.*` only for apps Nix is meant to own.
- **Live-edit configs:** for app config files that need to be tweaked without rebuilding (e.g. `niri.kdl`, `noctalia-settings.json`), use the `mkOutOfStoreSymlink` pattern documented in [`.agents/skills/live-edit-config`](.agents/skills/live-edit-config/SKILL.md). Skills live at `.agents/skills/` (auto-discovered by Codex, pi, Copilot); `.claude/skills` is a symlink to the same directory so Claude Code finds them too.

## The dendritic pattern (in one paragraph)

`flake.nix` contains no logic — it calls `flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)`. Every `.nix` file under `modules/` is auto-imported as a flake-parts module. There is no central `imports = [ ... ]` list to maintain: dropping a file in the tree is registration. File names and subdirectory layout are organizational only — the loader doesn't care. Configuration is organized by **concern (aspect)**, not by host.

```nix
# flake.nix — typical shape
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    den.url = "github:vic/den";
    home-manager.url = "github:nix-community/home-manager";
  };
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
```

A one-line module pulls den itself into the flake-parts module set:

```nix
# modules/dendritic.nix
{ inputs, ... }: { imports = [ inputs.den.flakeModule ]; }
```

## Den primitives

| Primitive | Purpose |
|---|---|
| `den.aspects.<name>` | Reusable bundle of class-keyed config (`nixos`, `homeManager`, `darwin`, ...) plus an `includes` list of other aspects |
| `den.hosts.<system>.<host>.users.<user> = { }` | Declares a machine + its users; produces `nixosConfigurations.<host>` |
| `den.homes.<system>.<name> = { }` | Declares a standalone home-manager configuration |
| `den.provides.*` (alias of `den.batteries.*`) | Pre-built "batteries" shipped by den (`primary-user`, `define-user`, `hostname`, `user-shell`, ...) |
| `den.schema.{host,user,home}` | Extends the typed option schema for entities; also carries `includes`/`excludes` — aspects/policies activated for every entity of that kind (e.g. default `classes`, custom options) |
| `den.default.*` | Global config applied to every host/user/home (state versions, nixpkgs config, etc.) |
| `den.policies.*` | Built-in and custom entity-topology/routing effects (e.g. `host-to-users`) activated via `includes` — replaces the old `den.ctx.<kind>.into` concept |

## Aspects

An aspect is a function of context that returns class-keyed config. Each class key (`nixos`, `homeManager`, ...) is a normal NixOS / home-manager module.

```nix
# modules/desktop.nix
{
  den.aspects.desktop.nixos = { pkgs, ... }: {
    programs.firefox.enable = true;
    programs.hyprland.enable = true;
    environment.systemPackages = [ pkgs.bitwarden-desktop ];
  };
}
```

Aspects can declare config for multiple classes at once and depend on other aspects via `includes`:

```nix
# modules/dev.nix
{ den, ... }:
{
  den.aspects.dev = {
    includes = [ den.aspects.shell den.provides.user-shell "fish" ];

    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.git pkgs.neovim ];
    };

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.ripgrep ];
    };
  };
}
```

Context-aware aspects take `{ host }`, `{ user }`, or `{ host, user }` and emit config whenever that shape is in scope:

```nix
den.aspects.setHost = { host, ... }: {
  nixos.networking.hostName = host.hostName;
};
```

## Hosts and users

Topology is a one-liner. Each entry generates a `nixosConfigurations.<host>`:

```nix
# modules/hosts.nix
{
  den.hosts.x86_64-linux.laptop.users.alice = { };
  den.hosts.aarch64-darwin.macbook.users.alice = { };
  den.homes.x86_64-linux.alice = { };
}
```

Per-host config goes in its own aspect, which is included by the host:

```nix
# modules/laptop.nix
{ den, ... }:
{
  den.aspects.laptop = {
    includes = [ den.aspects.desktop den.aspects.dev ];
    nixos = { ... }: {
      imports = [ ../hardware-configuration.nix ];
      networking.hostName = "laptop";
      time.timeZone = "UTC";
    };
  };
}
```

`hardware-configuration.nix` is normally kept **outside** `modules/` and imported explicitly — auto-importing it would apply the hardware to every host.

## Defaults and schema

Global settings and entity-schema extensions live in their own module:

```nix
# modules/defaults.nix
{ den, lib, ... }:
{
  systems = [ "x86_64-linux" ];

  den.default.nixos.system.stateVersion = "25.11";
  den.default.nixos.nixpkgs.config.allowUnfree = true;
  den.default.homeManager.home.stateVersion = "25.11";

  # Make every user a home-manager user by default.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # hostname battery is opt-in; apply it once here rather than per host.
  den.schema.host.includes = [ den.provides.hostname ];
}
```

Cross-entity config (a host aspect contributing to a user's home-manager, or
a user aspect contributing to a specific host) needs **no battery at all** —
it's built into the resolution pipeline. See `provides.<name>` in
[Mutual provider pattern](#mutual-provider-pattern) below. `den.ctx.*` and
`den.provides.mutual-provider` are deprecated/inert leftovers from an older
API — see [Caveats](#caveats).

Custom schema fields let aspects branch on host/user metadata:

```nix
den.schema.host = { lib, ... }: {
  options.isWorkstation = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
};
```

## Provides (batteries)

`den.provides.*` (= `den.batteries.*`) are reusable aspect fragments. Batteries
are either **opt-in** (you list them in some `includes`) or **auto-activated**
(den turns them on itself once a precondition is met — don't list those in
`includes`; several are policy bundles rather than includable aspects).

Opt-in:

- `den.provides.define-user` — creates the user account on the host
- `den.provides.primary-user` — marks the user as admin (`wheel`, `networkmanager`; also sets `wsl.defaultUser` on WSL hosts)
- `den.provides.hostname` — sets `networking.hostName`/Darwin hostname from `host.hostName`. This repo applies it once via `den.schema.host.includes` (see `modules/defaults.nix`) rather than per host.
- `den.provides.user-shell "fish"` — parametric: sets the user's login shell at both OS and HM level (see nushell caveat below)
- `den.provides.host-aspects` — opt-in escape hatch to forward a host aspect's `homeManager` content to its users (see the mutual-provider caveat below for why this is normally unneeded)

Auto-activated (no `includes` needed):

- `den.batteries.os-class` — the `os` class forwards into both `nixos` and `darwin`
- `den.batteries.os-user` — the `user` class forwards into the host's `users.users.<name>`; prefer `den.aspects.<host>.provides.<user>.user.extraGroups = [ ... ]` on the host aspect over hand-writing `users.users.<name>.extraGroups` in the host's `nixos` block
- `den.batteries.home-manager` — activates once any user has `"homeManager"` in `classes`; forwards that user's `homeManager` class into `home-manager.users.<name>`
- `den.batteries.wsl` — activates when `den.hosts.<sys>.<host>.wsl.enable = true;` is set; requires `inputs.nixos-wsl`. Do **not** hand-import `inputs.nixos-wsl.nixosModules.default` yourself — that's what this repo's `modules/wsl.nix` used to do before switching to `wsl.enable`.

`den.provides.mutual-provider` is a deprecated, **inert** compat shim — see [Caveats](#caveats).

Use opt-in batteries via `includes`:

```nix
den.aspects.alice.includes = [
  den.provides.define-user
  den.provides.primary-user
  (den.provides.user-shell "fish")
];
```

## Mutual provider pattern

Cross-entity routing is **built into the resolution pipeline** — no battery
needed. An aspect can target a specific pairing of host and user via a named
`provides.<name>` key, or fan out with `provides.to-hosts` / `provides.to-users`:

```nix
den.aspects.alice = {
  # Config that applies whenever alice is on the laptop host.
  provides.laptop.nixos.programs.nh.enable = true;
  # Config that applies to every host alice lives on.
  provides.to-hosts = { host, ... }: {
    nixos.programs.nh.enable = true;
  };
};

den.aspects.laptop = {
  # Config that applies to alice's home-manager when she's on this host.
  provides.alice.homeManager.programs.tmux.enable = true;
  # Config that applies to every user on this host.
  provides.to-users = { user, ... }: {
    homeManager.programs.helix.enable = user.name == "alice";
  };
};
```

A `provides` key on a **user** aspect is subtree-scoped: it reaches the named
host (or, with `to-hosts`, every host that user lives on) but never a sibling
user on the same host. A `provides` key on a **host** aspect reaches the named
user (or, with `to-users`, every user on that host) — that's the one to use
when you need to configure several users, or pick per-user, from one place.

## Adding things

- **New concern**: drop a `.nix` file in `modules/` defining `den.aspects.<name>`. Reference it from a host's `includes`.
- **New host**: add `modules/<host>.nix` with `den.aspects.<host>`, then append `den.hosts.<system>.<host>.users.<user> = { };` to the topology module.
- **New user**: add a user aspect, include `den.provides.define-user`, and add the user under the host's `users.<name>` in topology.
- **No-op file removal**: deleting a file under `modules/` removes it from the build with no other edits — there's nothing else to unregister.

## Caveats

- `den.default.includes` runs for **every** host/user/home — be careful with parametric functions there. Use `den.lib.perHost` / `perUser` / `perHome` to scope cleanly.
- Aspects are merged like NixOS modules; a `homeManager` block inside `den.aspects.foo` won't take effect unless the user has `"homeManager"` in their `den.schema.user.classes`.
- The `<den/...>` and `<eg/...>` angle-bracket syntax in den examples is sugar for `den.provides.<name>` / namespace lookups; it requires `__findFile` to be in scope. Plain dotted access works the same.
- **Flakes only see git-tracked files.** A new `modules/<foo>.nix` (or any data file referenced from one) must be `git add`-ed before `nix flake check` / `nixos-rebuild` can find it, even before committing. The failure mode is a cryptic `attribute 'foo' missing` on `den.aspects.foo`.
- **`den.batteries.user-shell <shell>`** (also exposed as `den.provides.user-shell`) enables `programs.${shell}` at both the NixOS and home-manager class levels. That works for shells with a system-level module (bash, zsh, fish) but **breaks for HM-only shells like nushell** because there is no `programs.nushell` NixOS option. For those, set `users.users.<name>.shell = pkgs.<shell>;` directly and skip the battery. (The HM half of the battery also writes shell-config files, which conflicts with chezmoi-style external dotfile management — another reason to bypass it.)
- **`den.ctx.*` is deprecated.** It's a compat shim (`den.ctx.<kind>.includes` forwards to `den.schema.<kind>.includes` with a `lib.warn`); `den.ctx.<kind>.into` is gone (was for policy activation, now `den.policies`). Write `den.schema.<kind>.includes` directly.
- **`den.provides.mutual-provider` (`den.batteries.mutual-provider`) is an inert no-op.** Cross-entity `provides.<name>` / `provides.to-hosts` / `provides.to-users` routing is built into the pipeline; including the battery changes nothing. Don't add it — `modules/defaults.nix` no longer does.
- **Class/context mismatch silently drops content** — eval succeeds, but nothing applies. Content only takes effect when the resolving context has a forwarder for its class. Cases we've hit, matched against current pipeline behavior:
  - `provides.<name>` on a **user** aspect is subtree-scoped: it reaches the named host (or every host, via `to-hosts`) but never reaches a sibling user on the same host. Put multi-user or per-user routing in the **host** aspect's `provides.<user>` / `provides.to-users` instead — that subtree spans every user on the host.
  - `homeManager.*` on an aspect included only by a **host** (not by the user, and not routed through `provides`) does **not** reach the user's home-manager. Either put the aspect in the **user** aspect's `includes`, route it as `provides.<user>.homeManager.*` / `provides.to-users` on the host aspect, or opt the user into `den.provides.host-aspects`.
  - A host-scope **parametric** `{ user, ... }` aspect no longer leaks `homeManager` content to users, even though it fans out per-user — it emits class-locally on the host, where `homeManager` is inert. (Earlier den releases did leak this; that behavior is gone.) Route such content through `provides`, `to-users`, or `den.provides.host-aspects` instead of relying on the fan-out alone.
- **HM activation failure blocks new system generations.** If `home-manager-<user>.service` fails during `switch-to-configuration switch`, the script exits non-zero and `nix-env --set` on `/nix/var/nix/profiles/system` never runs — so no new `system-N-link` is created. Symptom: rebuilds appear to succeed (build + bootloader install log fine) but `readlink /nix/var/nix/profiles/system` stays pinned to an old generation, and to a user it looks like "rebuilds aren't doing anything" or "we hit a generation cap." There is no cap. Always tail the rebuild log; the failing user unit is named in the output. `journalctl -u home-manager-<user>.service -b` has the details.
- **HM can corrupt the user nix-env profile manifest.** A failed HM activation (or interrupted `nix-env --set`) sometimes leaves `~/.local/state/nix/profiles/profile-N-link/manifest.nix` as a **0-byte file**. Every subsequent rebuild then dies with `syntax error, unexpected end of file at env-manifest.nix:1:1`. Recover by rolling the user profile back to the previous good generation: `nix-env --switch-generation <N-1> -p ~/.local/state/nix/profiles/profile`, then rebuild. Check manifest sizes with `for p in ~/.local/state/nix/profiles/profile-*-link; do stat -c '%s %n' "$p"/manifest.nix 2>/dev/null; done`.
- **Third-party HM modules often gate features on multiple toggles** — `programs.<x>.enable = true` is frequently *just* "install the binary + write configs," with the autostart systemd user service hidden behind a separate `programs.<x>.systemd.enable` (or `.service.enable`). Symptom: the binary appears in `~/.nix-profile/bin` but `systemctl --user status <x>.service` reports "Unit could not be found." When an app installs but never autostarts in the graphical session, read the upstream HM module source (look for `systemd.user.services.<x> = lib.mkIf cfg.systemd.enable …` or similar) to find the missing toggle. Example: `programs.noctalia-shell.enable` alone is not enough; you also need `programs.noctalia-shell.systemd.enable = true` for the service that's `WantedBy = [ wayland.systemd.target ]`.

## References

- `github:denful/den` (renamed from `vic/den`) — den source and templates (`templates/{minimal,default,example}/`)
- <https://den.denful.dev> — docs site (`den.oeiuwq.com` 301-redirects here). Useful pages:
  - `reference/batteries.mdx` — full battery list, opt-in vs auto-activated
  - `reference/schema.mdx` — `den.schema`, `den.hosts`, `den.homes` option reference
  - `reference/aspects.mdx` — aspect structure and resolution
  - `guides/mutual.mdx` — cross-entity `provides` routing (host↔user)
  - `guides/home-manager.mdx` — HM/hjem/maid integration, host-scope parametric-aspect caveat
  - `guides/migrate-ctx.mdx` — migrating off `den.ctx.*`
- <https://codeberg.org/Adda/nixos-config> — substantial real-world layout using this pattern
