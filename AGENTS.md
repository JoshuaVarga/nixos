# Den Patterns

## Aspect Pattern

An aspect is a context-driven, multi-class configuration function that activates different Nix classes based on context.

```nix
den.aspects.NAME = { host, user }@ctx: {
  nixos = { pkgs, ... }: { /* nixos module */ };
  darwin = { pkgs, ... }: { /* darwin module */ };
  homeManager = { pkgs, ... }: { /* hm module */ };
  
  # Aspect dependencies (DAG)
  includes = [ den.aspects.other-aspect ];
  
  # Nested sub-aspects
  provides.SUB = {
    nixos = { pkgs, ... }: { /* ... */ };
  };
};
```

## Context Transformation Pipeline

Contexts are transformed through stages. A context is only valid if it matches function parameters via `__functor` argument introspection.

```
host {host}
  ↓
user {host, user} (for each user)
  ↓
home {host, user, home} (derived contexts: hm-host, hm-user, wsl-host, etc.)
```

Functions receive only contexts whose shape matches their parameters.

## Resolution

Three-step instantiation:

```nix
# 1. Create context via pipeline transformations
aspect = den.ctx.host { host = den.hosts.x86_64-linux.my-laptop; };

# 2. Resolve aspect for a specific class
nixosModule = den.lib.aspects.resolve "nixos" aspect;

# 3. Instantiate with system API
nixosConfigurations.my-laptop = lib.nixosSystem { modules = [ nixosModule ]; };
```

## Schema Pattern

Extensible base modules for declaring host/user/home metadata. Schema transforms are applied before aspects.

```nix
den.schema.user = { user, lib, ... }: {
  config.classes = if user.userName == "vic" then [ "hjem" "maid" ] else [ "homeManager" ];
  options.mainGroup = lib.mkOption { default = user.userName; };
};
```

## Forwarding Pattern

A guard-aware mechanism to route one class into another. Used for custom classes (`user`, `wsl`, `microvm`, etc.) and guarded platform-aware configurations.

```nix
den._.forward {
  each = [ "item1" "item2" ];
  fromClass = item: "prefix-${item}";
  intoClass = _: "target-class";
  intoPath = _: [ "path" "segments" ];
  fromAspect = _: aspect-to-apply;
  guard = { config, pkgs, ... }: item: lib.mkIf (condition);
};
```

## Parametric Aspect Pattern

Aspects as functions accepting parameters to create variants.

```nix
den.provides.user-shell = shell: {
  homeManager = { pkgs, ... }: { programs.${shell}.enable = true; };
};

# Usage
includes = [ (den.provides.user-shell "fish") ];
```

## Multi-Class Aspect Example

A single aspect defining behavior across multiple domains:

```nix
den.aspects.workstation = {
  includes = [ den.provides.hostname ];
  
  nixos = { pkgs, ... }: { /* nixos config */ };
  darwin = { pkgs, ... }: { /* darwin config */ };
  
  # Custom class for shared logic
  os = { pkgs, ... }: { environment.systemPackages = [ pkgs.direnv ]; };
  
  # Provide config to users on host
  provides.to-users = {
    homeManager = { pkgs, ... }: { programs.vim.enable = true; };
  };
};
```

## User Aspect with Host-Specific Overrides

Users can contribute OS-level configs and host-specific variants.

```nix
den.aspects.USERNAME = {
  homeManager = { pkgs, ... }: { /* hm config */ };
  darwin.services.karabiner-elements.enable = true;
  
  # User class that forwards to {nixos/darwin}.users.users.<userName>
  user = { pkgs, ... }: { packages = [ pkgs.helix ]; };
  
  # Host-specific configurations
  provides.rog-tower = {
    nixos = { /* enable CUDA */ };
  };
};
```

## Namespace Pattern

Allows publishing and consuming aspect libraries across flakes or non-flakes.

```nix
den.lib.namespace.register "namespace:name" {
  /* aspect definitions */
};

# From another flake
den.lib.namespace.import "namespace:name"
```
