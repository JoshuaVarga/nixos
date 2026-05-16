{ den, lib, ... }:
{
  systems = [ "x86_64-linux" ];

  den.default.nixos.system.stateVersion = "25.11";
  den.default.nixos.nixpkgs.config.allowUnfree = true;
  den.default.nixos.home-manager.backupFileExtension = "bak";
  den.default.homeManager.home.stateVersion = "25.11";

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.ctx.user.includes = [ den.provides.mutual-provider ];
}
