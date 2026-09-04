{
  den.aspects.shell.homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        carapace
        nushell
        starship
        wezterm
      ];
    };
}
