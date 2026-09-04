{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs.nixfmt.enable = true;
      programs.deadnix.enable = true;
      programs.statix.enable = true;

      settings.global.excludes = [
        "modules/noctalia-settings.toml"
        "hardware-configuration.nix"
        "flake.lock"
      ];
    };
  };
}
