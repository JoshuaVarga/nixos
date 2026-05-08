{
  den.aspects.shell.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        carapace
        nushell
        starship
        wezterm
      ];
    };
}
