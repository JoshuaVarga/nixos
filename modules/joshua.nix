{ den, inputs, ... }:
{
  den.aspects.joshua = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      den.aspects.shell
    ];

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.omp.homeManagerModules.default ];

        programs.omp = {
          enable = true;
          settings.startup.quiet = true;
        };

        home.packages = with pkgs; [
          tree
        ];
      };
  };
}
