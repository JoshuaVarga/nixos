{ den, ... }:
{
  den.aspects.joshua = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
      den.aspects.shell
    ];

    nixos =
      { pkgs, ... }:
      {
        users.users.joshua.shell = pkgs.nushell;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = with pkgs; [
          tree
        ];
      };
  };
}
