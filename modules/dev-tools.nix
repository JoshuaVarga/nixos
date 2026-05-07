{
  den.aspects.dev-tools.nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        git
        vim
        neovim
        chezmoi
        wget
        claude-code
      ];
    };
}
