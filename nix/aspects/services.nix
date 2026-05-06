{ den, inputs, lib }:
{ host, ... }@ctx:
{
  nixos = { config, pkgs, ... }: {
    programs.firefox.enable = true;
    programs.ssh.startAgent = true;

    services.openssh.enable = true;
    services.tuned.enable = true;
    services.upower.enable = true;
    services.greetd = {
      enable = true;
      settings.default_session = {
        command = "start-hyprland";
        user = "joshua";
      };
    };
  };
}
