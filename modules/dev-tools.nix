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
        pi-coding-agent
        gcc
        lazygit
        fzf
        ripgrep
        fd
        curl
        tree-sitter
      ];
    };
}
