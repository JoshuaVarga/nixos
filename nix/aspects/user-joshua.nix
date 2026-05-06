{ den, inputs, lib }:
{ host, user, ... }@ctx:
{
  # Include feature aspects for this user
  includes = [
    den.aspects.desktop
    den.aspects.shell
    den.aspects.dev-tools
  ];

  # User-specific system config
  nixos = { config, pkgs, ... }: {
    users.users.joshua.packages = with pkgs; [
      tree
    ];
  };

  # User's home-manager configuration
  homeManager = { config, pkgs, ... }: {
    home.username = "joshua";
    home.homeDirectory = "/home/joshua";
    home.stateVersion = "25.11";
  };
}
