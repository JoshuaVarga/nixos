{ den, ... }:
{
  den.aspects.titan = {
    includes = [
      den.aspects.desktop
      den.aspects.niri
      den.aspects.services
      den.aspects.shell
      den.aspects.dev-tools
      den.aspects.nh
      den.aspects.nvidia
      den.aspects.steam
    ];

    provides.joshua.homeManager =
      { config, ... }:
      {
        xdg.configFile."niri/config.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/niri.kdl";
      };

    nixos =
      { pkgs, ... }:
      {
        imports = [ ../hardware-configuration.nix ];

        boot.loader.limine.enable = true;
        boot.loader.limine.secureBoot = {
          enable = true;
          autoGenerateKeys = true;
          autoEnrollKeys.enable = true;
        };
        boot.loader.efi.canTouchEfiVariables = true;

        networking.hostName = "titan";
        networking.networkmanager.enable = true;

        time.timeZone = "Canada/Toronto";

        hardware.graphics.enable = true;
        hardware.bluetooth.enable = true;
      };
  };
}
