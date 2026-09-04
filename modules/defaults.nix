{ den, lib, ... }:
{
  systems = [ "x86_64-linux" ];

  den.default.nixos = {
    system.stateVersion = "25.11";
    nixpkgs.config.allowUnfree = true;
    home-manager.backupFileExtension = "bak";
    systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp";
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
  den.default.homeManager.home.stateVersion = "25.11";

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.schema.host.includes = [
    den.provides.hostname
    den.aspects.version
  ];
}
