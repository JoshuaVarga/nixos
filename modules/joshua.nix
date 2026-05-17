{ den, ... }:
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
        home.packages = with pkgs; [
          tree
        ];
      };
  };
}
