# Example: Adding a Darwin (macOS) Host

This is a future extension example showing how Den enables cross-platform configurations.

## Structure

```
nix/
├── aspects/
│   └── hardware/
│       └── mac-apple-silicon.nix    (darwin-specific)
```

## Step-by-step

### 1. Define Darwin host in nix/schemas/hosts.nix

```nix
den.hosts."aarch64-darwin".mac = {
  system = "aarch64-darwin";
  class = "darwin";
  users.joshua = { };
};
```

### 2. Create hardware aspect for Darwin

```nix
# nix/aspects/hardware/mac-apple-silicon.nix
{ den, inputs, lib }:
{ host, ... }@ctx:
{
  darwin = { config, pkgs, ... }: {
    # Darwin-specific configuration
    system.defaults.dock.autohide = true;
  };
}
```

### 3. Share desktop/shell/dev-tools across platforms

The existing `desktop`, `shell`, `dev-tools` aspects can be enhanced:

```nix
# nix/aspects/desktop.nix
{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { ... }: { programs.hyprland.enable = true; };
  
  # Darwin equivalent
  darwin = { ... }: { 
    services.karabiner-elements.enable = true;
  };
}
```

### 4. Add Darwin outputs to flake.nix

```nix
darwinConfigurations.mac = darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  modules = [
    # Compose aspects for mac
  ];
};

homeConfigurations."joshua@mac" = home-manager.lib.homeManagerConfiguration {
  pkgs = nixpkgs.legacyPackages.aarch64-darwin;
  modules = [
    # Home config for mac user
  ];
};
```

## Why Den Makes This Easy

1. **Aspect Reuse**: `dev-tools`, `shell` configs can use conditional logic based on host class
2. **Platform Isolation**: Hardware and platform-specific configs stay separate
3. **Context Awareness**: Aspects receive `host` context enabling platform-aware decisions
4. **No Duplication**: User config stays once, but resolves for both NixOS and Darwin

## Guarded Forwarding for Platform Awareness

Den supports advanced patterns like guarded forwarding to automatically select platform-specific implementations:

```nix
den._.forward {
  each = [ "Linux" "Darwin" ];
  fromClass = platform: "desktop-${platform}";
  intoClass = _: "nixos";
  # Only apply on Linux, skip on Darwin
  guard = { config, pkgs, ... }: _: lib.mkIf pkgs.stdenv.isLinux;
};
```
