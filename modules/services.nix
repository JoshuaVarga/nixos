{
  den.aspects.services.nixos = {
    programs.ssh.startAgent = true;

    services.openssh.enable = true;
    services.tuned.enable = true;
    services.upower.enable = true;
    services.mullvad-vpn.enable = true;

    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "niri-session";
        user = "joshua";
      };
    };
  };
}
