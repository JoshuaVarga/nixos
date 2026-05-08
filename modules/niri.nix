{
  den.aspects.niri = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          niri
          xwayland-satellite
        ];

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gnome
            xdg-desktop-portal-gtk
          ];
        };

        security.polkit.enable = true;
      };

    homeManager =
      { config, ... }:
      {
        xdg.configFile."niri/config.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/niri.kdl";
      };
  };
}
