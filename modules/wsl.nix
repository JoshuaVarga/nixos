{ den, ... }:
{
  den.aspects.wsl = {
    includes = [
      den.aspects.shell
      den.aspects.dev-tools
      den.aspects.nh
    ];

    nixos = {
      time.timeZone = "Canada/Toronto";

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
