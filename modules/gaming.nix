{ den, ... }:
{
  den.aspects.gaming = {
    includes = [
      den.aspects.steam
    ];

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.deadlock-mod-manager
        ];
      };
  };
}
