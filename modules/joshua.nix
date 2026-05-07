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
        users.users.joshua.packages = with pkgs; [
          tree
        ];
      };
  };
}
