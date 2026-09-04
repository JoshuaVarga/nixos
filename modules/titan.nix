{ den, inputs, ... }:
{
  den.aspects.titan = {
    includes = [
      den.aspects.desktop
      den.aspects.niri
      den.aspects.services
      den.aspects.dev-tools
      den.aspects.nh
      den.aspects.nvidia
      den.aspects.gaming
      den.aspects.ai
      den.aspects.memory
    ];

    provides.joshua.user.extraGroups = [ "i2c" ];

    provides.joshua.homeManager =
      { config, pkgs, ... }:
      {
        imports = [ inputs.noctalia.homeModules.default ];
        programs.noctalia.enable = true;
        programs.noctalia.systemd.enable = true;

        home.pointerCursor = {
          enable = true;
          package = pkgs.xcursor-pro;
          name = "XCursor-Pro-Red";
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };

        xdg.configFile."niri/config.kdl".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/niri.kdl";
        xdg.configFile."noctalia/config.toml".source =
          config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/noctalia-settings.toml";
      };

    nixos =
      { ... }:
      {
        imports = [ ../hardware-configuration.nix ];

        boot.loader.limine.enable = true;
        boot.loader.limine.efiInstallAsRemovable = true;
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

        fileSystems."/mnt/games" = {
          device = "/dev/disk/by-uuid/952f2e14-5b74-48fa-b837-baf9a1d0253d";
          fsType = "ext4";
          options = [
            "defaults"
            "nofail"
          ];
        };

        systemd.tmpfiles.rules = [
          "d /mnt/games 0755 joshua users -"
        ];
      };
  };
}
