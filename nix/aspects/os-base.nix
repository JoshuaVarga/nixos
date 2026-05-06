{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    # Boot configuration
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # Networking
    networking.hostName = host.name or "nixos";
    networking.networkmanager.enable = true;

    # Time
    time.timeZone = "Canada/Toronto";

    # User base configuration
    users.users.joshua = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
    };

    # Hardware support
    hardware.graphics.enable = true;
    hardware.bluetooth.enable = true;

    # Nix configuration
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # System state version
    system.stateVersion = "25.11";
  };
}
