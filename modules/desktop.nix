{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;

      fonts.packages = [ pkgs.nerd-fonts.fira-code ];

      hardware.i2c.enable = true;

      environment.systemPackages = [
        pkgs.bitwarden-desktop
        pkgs.ddcutil
        pkgs.mullvad-vpn
        pkgs.protontricks
        pkgs.vesktop
        pkgs.winetricks
        pkgs.wl-clipboard
        pkgs.xcursor-pro
      ];
    };
}
