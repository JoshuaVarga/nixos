{ lib, ... }:
{
  den.aspects.nh.nixos = {
    programs.nh = {
      enable = true;
      clean = {
        enable = true;
        dates = "Sun 04:00:00";
        extraArgs = "--keep 5 --keep-since 7d";
      };
      flake = "/etc/nixos";
    };

    systemd.timers.nh-clean.timerConfig = {
      Persistent = lib.mkForce false;
      RandomizedDelaySec = "30m";
    };
  };
}
