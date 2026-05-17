# AGENTS.md

Guidance for working in repos that use **[den](https://github.com/denful/den)** ([docs](https://den.oeiuwq.com/)) with the **dendritic pattern**.

## Repo conventions

- **Commits:** single-line, lowercase, imperative subject. No body, no `Co-Authored-By` trailer (`git log --oneline` shows the existing style). If a change feels too big for one short subject, split it into multiple atomic commits.
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
| `den.provides.*` | Pre-built "batteries" shipped by den (`primary-user`, `define-user`, `mutual-provider`, `hostname`, `user-shell`, ...) |
| `den.schema.{host,user,home}` | Extends the typed option schema for entities (e.g. default `classes`, custom options) |
| `den.default.*` | Global config applied to every host/user/home (state versions, nixpkgs config, etc.) |
| `den.ctx.{host,user,home}` | Pipeline that resolves entities into class modules |

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

  # Enable cross-config: ${user}.provides.${host} and vice-versa.
  den.ctx.user.includes = [ den.provides.mutual-provider ];
}
```

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

`den.provides.*` are reusable aspect fragments. Common ones:

- `den.provides.define-user` — creates the user account on the host
- `den.provides.primary-user` — marks the user as admin (wheel, etc.)
- `den.provides.mutual-provider` — enables `provides.<host>` / `provides.<user>` cross-config
- `den.provides.hostname` — auto-sets `networking.hostName` from the host name
- `den.provides.user-shell "fish"` — parametric: sets the user's default shell

Use them via `includes`:

```nix
den.aspects.alice.includes = [
  den.provides.define-user
  den.provides.primary-user
  (den.provides.user-shell "fish")
];
```

## Mutual provider pattern

With `mutual-provider` enabled, an aspect can target a specific *pairing* of host and user:

```nix
den.aspects.alice = {
  # Config that applies whenever alice is on the laptop host.
  provides.laptop = { host, ... }: {
    nixos.programs.nh.enable = true;
  };
};

den.aspects.laptop = {
  # Config that applies to alice's home-manager when she's on this host.
  provides.alice = { user, ... }: {
    homeManager.programs.tmux.enable = user.name == "alice";
  };
};
```

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

## References

- `github:vic/den` — den source and templates (`templates/{minimal,default,example}/`)
- <https://den.oeiuwq.com/> — concept docs (aspects, context, schema, provides)
- <https://codeberg.org/Adda/nixos-config> — substantial real-world layout using this pattern
