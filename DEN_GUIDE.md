# Den Aspects Documentation

## Aspect Dependency Graph

```
user-joshua
├── desktop (hyprland, greetd)
├── shell (nushell, starship, kitty, wezterm)
└── dev-tools (git, vim, neovim, chezmoi, tree)

os-base (core NixOS: networking, boot, users, nix settings)
services (openssh, tuned, upower, greetd)
hardware-titan (hyperv_drm, modesetting)
```

## Aspect Structure

Each aspect is a function that returns a multi-class attrset:

```nix
{ den, inputs, lib }:
{ host, user }@ctx:
{
  # NixOS system configuration
  nixos = { config, pkgs, ... }: { /* ... */ };
  
  # home-manager user configuration (optional)
  homeManager = { config, pkgs, ... }: { /* ... */ };
}
```

## Adding a Second Host

To add a new x86_64-linux host (e.g., "server"):

### 1. Define the host in nix/schemas/hosts.nix

```nix
den.hosts."x86_64-linux".server = {
  system = "x86_64-linux";
  class = "nixos";
  users.alice = { };
};
```

### 2. Create hardware-specific aspect (nix/aspects/hardware/server.nix)

```nix
{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    # Hardware config specific to server
  };
}
```

### 3. Create user-specific aspect (nix/aspects/user-alice.nix)

```nix
{ den, inputs, lib }:
{ host, user, ... }@ctx:
{
  includes = [ den.aspects.dev-tools ];
  
  nixos = { config, pkgs, ... }: {
    users.users.alice = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };
  };
  
  homeManager = { config, pkgs, ... }: {
    home.username = "alice";
    home.homeDirectory = "/home/alice";
    home.stateVersion = "25.11";
  };
}
```

### 4. Update flake.nix nixosConfigurations

```nix
nixosConfigurations = {
  titan = /* existing config */;
  
  server = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./hardware-configuration.nix
      (import ./nix/aspects/os-base.nix { inherit den inputs lib; } ctx).nixos
      (import ./nix/aspects/services.nix { inherit den inputs lib; } ctx).nixos
      (import ./nix/aspects/hardware/server.nix { inherit den inputs lib; } ctx).nixos
      (import ./nix/aspects/user-alice.nix { inherit den inputs lib; } ctx).nixos
      # ... home-manager integration
    ];
  };
};
```

## Parametric Aspects (Future Enhancement)

Create reusable, parameterized aspects:

```nix
# nix/aspects/shells.nix
{ den, inputs, lib }:
shell: { host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      "${shell}"
    ];
  };
};

# Usage in user-joshua.nix
includes = [
  (den.aspects.shells "nushell")
  den.aspects.dev-tools
];
```

## Custom Classes (Advanced)

Den supports custom Nix classes for domain-specific configuration. Example: a "container" class for systemd-nspawn containers.

## Reusable Namespaces (Advanced)

Extract common aspects into shareable libraries:

```nix
den.lib.namespace.register "myorg:base" {
  os-base = /* ... */;
  services = /* ... */;
};

# From another flake
den.lib.namespace.import "myorg:base"
```

## Testing Aspects

Each aspect can be tested independently by evaluating it in isolation:

```bash
nix eval '.#nixosConfigurations.titan.config.programs.hyprland.enable'
nix eval '.#nixosConfigurations.titan.config.services.openssh.enable'
```
