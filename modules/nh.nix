{
  den.aspects.nh.nixos = {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
      flake = "/etc/nixos";
    };
  };
}
