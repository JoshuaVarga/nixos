{
  den.aspects.steam.nixos =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
      };

      hardware.graphics.extraPackages32 = with pkgs.pkgsi686Linux; [
        freetype
        fontconfig
      ];

      networking.firewall.allowedTCPPortRanges = [
        {
          from = 2302;
          to = 2306;
        }
      ];
      networking.firewall.allowedUDPPortRanges = [
        {
          from = 2302;
          to = 2306;
        }
      ];
    };
}
