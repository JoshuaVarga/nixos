{ inputs, ... }:
{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;
      programs.hyprland.enable = true;

      environment.systemPackages = [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.bitwarden-desktop
      ];
    };
}
