{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      git
      vim
      neovim
      chezmoi
      tree
    ];
  };

  homeManager = { config, pkgs, ... }: {
    # Dev-tool specific home-manager config can go here
  };
}
