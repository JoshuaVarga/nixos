{ inputs, ... }:
{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;
      programs.hyprland.enable = true;

      fonts.packages = [ pkgs.nerd-fonts.fira-code ];

      environment.systemPackages = [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.bitwarden-desktop
        pkgs.vesktop
      ];
    };
}
