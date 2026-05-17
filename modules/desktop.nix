{
  den.aspects.desktop.nixos =
    { pkgs, ... }:
    {
      programs.firefox.enable = true;

      fonts.packages = [ pkgs.nerd-fonts.fira-code ];

      environment.systemPackages = [
        pkgs.bitwarden-desktop
        pkgs.mullvad-vpn
        pkgs.vesktop
        pkgs.wl-clipboard
      ];
    };
}
