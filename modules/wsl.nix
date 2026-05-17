{ den, inputs, ... }:
{
  den.aspects.wsl = {
    includes = [
      den.provides.hostname
      den.aspects.shell
      den.aspects.dev-tools
      den.aspects.nh
    ];

    nixos = {
      imports = [ inputs.nixos-wsl.nixosModules.default ];
      wsl.enable = true;
      wsl.defaultUser = "joshua";
    };
  };
}
