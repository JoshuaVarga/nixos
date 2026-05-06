{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    programs.hyprland.enable = true;
  };
}
