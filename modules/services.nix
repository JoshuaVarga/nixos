{
  den.aspects.services.nixos = {
    programs.ssh.startAgent = true;

    services.openssh.enable = true;
    services.tuned.enable = true;
    services.upower.enable = true;
    services.mullvad-vpn.enable = true;
  };
}
