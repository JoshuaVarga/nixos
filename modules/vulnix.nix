{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      apps.vulnix-titan = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "vulnix-titan" ''
            exec ${pkgs.vulnix}/bin/vulnix --system \
              ${self.nixosConfigurations.titan.config.system.build.toplevel}
          ''
        );
      };
    };
}
