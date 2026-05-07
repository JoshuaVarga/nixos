{
  den.aspects.shell.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        nushell
        starship
        kitty
        wezterm
      ];
    };
}
