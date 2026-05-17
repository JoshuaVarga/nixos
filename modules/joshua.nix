{ den, ... }:
{
  den.aspects.joshua = {
    includes = [
      den.provides.define-user
      den.provides.primary-user
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
