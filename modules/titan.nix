{ den, inputs, ... }:
{
  den.aspects.titan = {
    includes = [
      den.provides.hostname
      den.aspects.desktop
      den.aspects.niri
      den.aspects.services
      den.aspects.dev-tools
      den.aspects.nh
      den.aspects.nvidia
      den.aspects.steam
    ];

    provides.joshua.homeManager =
      { config, ... }:
      {
        imports = [ inputs.noctalia.homeModules.default ];
        programs.noctalia-shell.enable = true;
        programs.noctalia-shell.systemd.enable = true;

        xdg.configFile."niri/config.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/niri.kdl";
        xdg.configFile."noctalia/settings.json".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/noctalia-settings.json";
      };

    nixos =
      { ... }:
      {
        imports = [ ../hardware-configuration.nix ];

        boot.loader.limine.enable = true;
        boot.loader.limine.secureBoot = {
          enable = true;
          autoGenerateKeys = true;
          autoEnrollKeys.enable = true;
        };
        boot.loader.efi.canTouchEfiVariables = true;

        networking.networkmanager.enable = true;

        time.timeZone = null;
        services.automatic-timezoned.enable = true;

        hardware.graphics.enable = true;
        hardware.bluetooth.enable = true;
      };
  };
}
