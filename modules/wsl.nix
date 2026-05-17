{ den, inputs, ... }:
{
  den.aspects.wsl = {
    includes = [
      den.aspects.shell
      den.aspects.dev-tools
      den.aspects.nh
    ];

    nixos = {
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      wsl.enable = true;
      wsl.defaultUser = "joshua";

      time.timeZone = "Canada/Toronto";

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
