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
        gcc
        lazygit
        fzf
        ripgrep
        fd
        curl
        tree-sitter
        yazi
        jq
        zoxide
        fastfetch
      ];
    };
}
