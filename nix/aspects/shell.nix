{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      nushell
      starship
      kitty
      wezterm
    ];
  };

  homeManager = { config, pkgs, ... }: {
    # Shell configuration handled in home-manager
  };
}
